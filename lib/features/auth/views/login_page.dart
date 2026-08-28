import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/features/auth/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  String get _completePhoneNumber => '+20${_phoneController.text.trim().replaceFirst(RegExp(r'^0+'), '')}';

  void _sendCode() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().sendOtp(_completePhoneNumber);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.login)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthCodeSent) {
                    context.go('/otp?phone=${Uri.encodeComponent(state.phoneNumber)}');
                  } else if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.content_cut, size: 64, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(loc.loginSubtitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 32),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _sendCode(),
                        decoration: InputDecoration(labelText: loc.phoneNumber, hintText: loc.egyptianPhoneHint, prefixText: '+20  ', border: const OutlineInputBorder()),
                        validator: (value) {
                          final number = value?.trim().replaceFirst(RegExp(r'^0+'), '') ?? '';
                          return RegExp(r'^1[0125][0-9]{8}$').hasMatch(number) ? null : loc.invalidEgyptianPhone;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) => ElevatedButton(
                        onPressed: state is AuthLoading ? null : _sendCode,
                        child: state is AuthLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(loc.sendCode),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
