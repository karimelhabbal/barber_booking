import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial()) {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      emit(AuthAuthenticated());
    }

    _authStateSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        emit(AuthAuthenticated());
      } else if (state is! AuthCodeSent && state is! AuthLoading) {
        emit(AuthInitial());
      }
    });
  }

  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  late final StreamSubscription<fb.User?> _authStateSubscription;

  String? verificationId;
  String? phoneNumber;

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }

  Future<void> sendOtp(String phone) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      emit(const AuthError('Phone number is required'));
      return;
    }

    phoneNumber = normalizedPhone;
    emit(AuthLoading());

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          emit(AuthAuthenticated());
        },
        verificationFailed: (fb.FirebaseAuthException exception) {
          emit(AuthError(exception.message ?? 'Unable to send OTP'));
        },
        codeSent: (String verificationId, int? resendToken) {
          this.verificationId = verificationId;
          emit(AuthCodeSent(normalizedPhone));
        },
        codeAutoRetrievalTimeout: (String timeoutVerificationId) {
          verificationId = timeoutVerificationId;
        },
      );
    } on fb.FirebaseAuthException catch (exception) {
      emit(AuthError(exception.message ?? 'Unable to send OTP'));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> verifyOtp(String smsCode) async {
    final normalizedCode = smsCode.trim();
    if (verificationId == null || normalizedCode.isEmpty) {
      emit(const AuthError('Verification code is required'));
      return;
    }

    emit(AuthLoading());

    try {
      final credential = fb.PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: normalizedCode,
      );
      await _auth.signInWithCredential(credential);
      emit(AuthAuthenticated());
    } on fb.FirebaseAuthException catch (exception) {
      emit(AuthError(exception.message ?? 'Invalid verification code'));
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());

    try {
      await _auth.signOut();
      verificationId = null;
      phoneNumber = null;
      emit(AuthInitial());
    } catch (error) {
      emit(AuthError(error.toString()));
    }
  }
}
