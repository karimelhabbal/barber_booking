import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _phoneNumber = '';

  Future<void> _sendCode() async {
    final phone = _phoneNumber.trim();

    if (phone.isEmpty) {
      final loc = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.invalidPhoneNumber)));

      return;
    }

    await context.read<AuthCubit>().loginWithPhone(phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

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
        // appBar: AppBar(title: Text(loc.login), centerTitle: true),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 48.0
                  : 24.0;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  32,
                  horizontalPadding,
                  24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      Icon(
                        Icons.content_cut_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),

                      const SizedBox(height: 24),

                      Text(
                        loc.login,
                        textAlign: TextAlign.center,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        loc.phoneNumber,
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 36),

                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: IntlPhoneField(
                          decoration: InputDecoration(
                            labelText: loc.phoneNumber,
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          initialCountryCode: 'EG',
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          onChanged: (phone) {
                            _phoneNumber = phone.completeNumber;
                          },
                          onSubmitted: (_) {
                            final state = context.read<AuthCubit>().state;

                            if (state is! AuthLoading) {
                              _sendCode();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 24),

                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;

                          return SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: isLoading ? null : _sendCode,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      loc.sendCode,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loc.noAccount,
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              context.go('/register');
                            },
                            child: Text(
                              loc.createAccount,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      const Divider(),

                      const SizedBox(height: 20),

                      Text(
                        'دخول الحلاق',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 8),

                      TextButton.icon(
                        onPressed: () {
                          context.go('/barber-login');
                        },
                        icon: const Icon(Icons.content_cut_rounded),
                        label: const Text(
                          'دخول الحلاق',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
