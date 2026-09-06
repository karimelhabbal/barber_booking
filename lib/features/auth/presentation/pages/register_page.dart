import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  String _phoneNumber = '';

  Future<void> _register() async {
    final loc = AppLocalizations.of(context)!;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_phoneNumber.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.invalidPhoneNumber)));
      return;
    }

    await context.read<AuthCubit>().register(
      name: _nameController.text,
      phone: _phoneNumber,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthCodeSent) {
          context.go('/otp?phone=${Uri.encodeComponent(state.phoneNumber)}');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.code.localizedMessage(loc))),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(loc.register)),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: loc.name,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return loc.invalidName;
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: loc.phoneNumber,
                    border: const OutlineInputBorder(),
                  ),
                  initialCountryCode: 'EG',
                  onChanged: (phone) {
                    _phoneNumber = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 24),
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _register,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(loc.register),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
