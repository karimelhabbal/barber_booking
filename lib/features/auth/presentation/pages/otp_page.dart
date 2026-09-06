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
        appBar: AppBar(title: Text(loc.otpCode)),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.phoneNumber, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              PinCodeTextField(
                appContext: context,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoFocus: true,
                enableActiveFill: false,
                onChanged: (value) {
                  _otpCode = value;
                },
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _verifyCode,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(loc.verifyCode),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;

                  return TextButton(
                    onPressed: isLoading || !_isResendEnabled
                        ? null
                        : _resendOtp,
                    child: Text(
                      _isResendEnabled ? loc.resendCode : '$_resendSeconds',
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
