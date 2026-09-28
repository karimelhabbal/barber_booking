import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:barber_booking/core/l10n/app_localizations.dart';
import 'package:barber_booking/core/utils/auth_error_mapper.dart';
import 'package:barber_booking/features/auth/presentation/cubit/auth_cubit.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  Timer? _resendTimer;

  int _resendSeconds = 60;

  String _otpCode = '';

  bool get _isResendEnabled => _resendSeconds == 0;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    _resendSeconds = 60;

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSeconds == 0) {
        timer.cancel();
        return;
      }

      setState(() {
        _resendSeconds--;
      });
    });
  }

  Future<void> _verifyCode() async {
    final code = _otpCode.trim();

    if (code.length != 6) {
      final loc = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(loc.invalidVerificationCode)));

      return;
    }

    await context.read<AuthCubit>().verifyOtp(code: code);
  }

  Future<void> _resendOtp() async {
    if (!_isResendEnabled) {
      return;
    }

    final cubit = context.read<AuthCubit>();

    await cubit.resendOtp();

    if (!mounted) {
      return;
    }

    if (cubit.state is AuthCodeSent) {
      setState(() {
        _otpCode = '';
      });

      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/dashboard');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.code.localizedMessage(loc))),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(loc.otpCode), centerTitle: true),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 600
                  ? 48.0
                  : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      children: [
                        const SizedBox(height: 24),

                        Icon(
                          Icons.verified_user_outlined,
                          size: 56,
                          color: Theme.of(context).colorScheme.primary,
                        ),

                        const SizedBox(height: 24),

                        Text(
                          loc.otpTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),

                        const SizedBox(height: 12),

                        Text(
                          loc.otpSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),

                        const SizedBox(height: 8),

                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            widget.phoneNumber,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),

                        const SizedBox(height: 32),

                        PinCodeTextField(
                          appContext: context,
                          length: 6,
                          keyboardType: TextInputType.number,
                          animationType: AnimationType.fade,
                          autoFocus: true,
                          enableActiveFill: true,
                          textStyle: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          pinTheme: PinTheme(
                            shape: PinCodeFieldShape.box,
                            borderRadius: BorderRadius.circular(12),
                            fieldHeight: 56,
                            fieldWidth: 48,
                            activeColor: Theme.of(context).colorScheme.primary,
                            selectedColor: Theme.of(context)
                                .colorScheme
                                .primary,
                            inactiveColor: Theme.of(context)
                                .colorScheme
                                .outlineVariant,
                            activeFillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            selectedFillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            inactiveFillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          onChanged: (value) {
                            _otpCode = value;
                          },
                          onCompleted: (_) {
                            _verifyCode();
                          },
                        ),

                        const SizedBox(height: 28),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: FilledButton(
                                onPressed: isLoading ? null : _verifyCode,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(loc.verifyCode),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;

                            return TextButton(
                              onPressed: isLoading || !_isResendEnabled
                                  ? null
                                  : _resendOtp,
                              child: Text(
                                _isResendEnabled
                                    ? loc.otpResendAvailable
                                    : '${loc.otpResendIn} $_resendSeconds',
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
