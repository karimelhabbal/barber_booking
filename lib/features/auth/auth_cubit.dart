import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/foundation.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit()
    : super(
        firebase_core.Firebase.apps.isNotEmpty &&
                fb.FirebaseAuth.instance.currentUser != null
            ? AuthAuthenticated()
            : AuthInitial(),
      );

  fb.FirebaseAuth? get _auth =>
      firebase_core.Firebase.apps.isNotEmpty ? fb.FirebaseAuth.instance : null;

  String? _verificationId;
  fb.ConfirmationResult? _confirmationResult;
  int? _resendToken;
  bool _phoneRequestInFlight = false;

  Future<void> loginWithPhone({required String phone}) => sendOtp(phone);

  Future<void> sendOtp(String phone) async {
    // Web Auth owns the invisible reCAPTCHA lifecycle. Starting a second
    // request before the first one settles can replace its DOM container while
    // the Google script is still using it.
    if (_phoneRequestInFlight) return;

    final auth = _auth;
    if (auth == null) {
      emit(
        const AuthError('Firebase is not initialized. Please restart the app.'),
      );
      return;
    }

    _phoneRequestInFlight = true;
    _confirmationResult = null;
    emit(AuthLoading());
    try {
      if (kIsWeb) {
        _confirmationResult = await auth.signInWithPhoneNumber(phone);
        emit(AuthCodeSent(phone));
        return;
      }
      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        emit(
          const AuthError(
            'Phone verification is not supported by Firebase Auth on this platform. Use Android, iOS, or the web app.',
          ),
        );
        return;
      }
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (credential) async {
          try {
            await auth.signInWithCredential(credential);
            emit(AuthAuthenticated());
          } on fb.FirebaseAuthException catch (error) {
            emit(AuthError(_messageFor(error)));
          } catch (_) {
            emit(const AuthError('Unable to complete phone verification.'));
          }
        },
        verificationFailed: (error) => emit(AuthError(_messageFor(error))),
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          emit(AuthCodeSent(phone));
        },
        codeAutoRetrievalTimeout: (verificationId) =>
            _verificationId = verificationId,
      );
    } on fb.FirebaseAuthException catch (error) {
      emit(AuthError(_messageFor(error)));
    } catch (_) {
      emit(
        const AuthError(
          'Unable to send the verification code. Please try again.',
        ),
      );
    } finally {
      _phoneRequestInFlight = false;
    }
  }

  Future<void> verifyOtp(String code) async {
    final auth = _auth;
    if (auth == null) {
      emit(
        const AuthError('Firebase is not initialized. Please restart the app.'),
      );
      return;
    }
    emit(AuthLoading());
    try {
      final confirmationResult = _confirmationResult;
      if (confirmationResult != null) {
        await confirmationResult.confirm(code);
      } else {
        final verificationId = _verificationId;
        if (verificationId == null) {
          emit(
            const AuthError('Request a new verification code and try again.'),
          );
          return;
        }
        await auth.signInWithCredential(
          fb.PhoneAuthProvider.credential(
            verificationId: verificationId,
            smsCode: code,
          ),
        );
      }
      emit(AuthAuthenticated());
    } on fb.FirebaseAuthException catch (error) {
      emit(AuthError(_messageFor(error)));
    } catch (_) {
      emit(const AuthError('Unable to verify the code. Please try again.'));
    }
  }

  Future<void> register({required String name, required String phone}) =>
      sendOtp(phone);

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) {
      emit(AuthUnauthenticated());
      return;
    }
    try {
      await auth.signOut();
      emit(AuthUnauthenticated());
    } on fb.FirebaseAuthException catch (error) {
      emit(AuthError(_messageFor(error)));
    } catch (_) {
      emit(const AuthError('Unable to sign out. Please try again.'));
    }
  }

  String _messageFor(fb.FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Enter a valid phone number.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect.';
      case 'session-expired':
        return 'This verification code has expired. Request a new one.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait before trying again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Phone sign-in is not enabled for this Firebase project.';
      case 'unauthorized-domain':
        return 'This web domain is not authorized for Firebase phone sign-in.';
      case 'captcha-check-failed':
      case 'missing-app-credential':
        return 'reCAPTCHA verification failed. Please try again.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
