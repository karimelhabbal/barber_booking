import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

abstract interface class AuthRemoteDataSource {
  fb.User? get currentUser;

  Future<void> sendLoginOtp({required String phone});

  Future<void> sendRegistrationOtp({
    required String name,
    required String phone,
  });

  Future<void> resendOtp();

  Future<fb.User> verifyOtp({required String code});

  Future<fb.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this._firebaseAuth});

  final fb.FirebaseAuth _firebaseAuth;

  String? _verificationId;
  fb.ConfirmationResult? _confirmationResult;
  int? _resendToken;

  String _currentPhone = '';

  int _requestId = 0;

  bool _requestInFlight = false;
  bool _verificationInFlight = false;

  @override
  fb.User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> sendLoginOtp({required String phone}) {
    return _sendOtp(phone: phone, forceResendingToken: null, isResend: false);
  }

  @override
  Future<void> sendRegistrationOtp({
    required String name,
    required String phone,
  }) {
    // Firebase Authentication only needs the phone number.
    // The name is handled by the repository/user data source.
    return _sendOtp(phone: phone, forceResendingToken: null, isResend: false);
  }

  @override
  Future<void> resendOtp() {
    if (_currentPhone.isEmpty) {
      return Future.error(fb.FirebaseAuthException(code: 'request-new-code'));
    }

    if (_verificationId == null &&
        _confirmationResult == null &&
        _resendToken == null) {
      return Future.error(fb.FirebaseAuthException(code: 'request-new-code'));
    }

    return _sendOtp(
      phone: _currentPhone,
      forceResendingToken: _resendToken,
      isResend: true,
    );
  }

  @override
  Future<fb.User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();

    if (normalizedEmail.isEmpty) {
      throw fb.FirebaseAuthException(code: 'invalid-email');
    }

    if (password.isEmpty) {
      throw fb.FirebaseAuthException(code: 'invalid-password');
    }

    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw fb.FirebaseAuthException(code: 'authentication-failed');
    }

    return user;
  }

  Future<void> _sendOtp({
    required String phone,
    required int? forceResendingToken,
    required bool isResend,
  }) async {
    if (_requestInFlight || _verificationInFlight) {
      return;
    }

    final normalizedPhone = phone.trim();

    if (normalizedPhone.isEmpty) {
      throw fb.FirebaseAuthException(code: 'invalid-phone-number');
    }

    _requestInFlight = true;

    final requestId = ++_requestId;

    _currentPhone = normalizedPhone;

    _verificationId = null;
    _confirmationResult = null;

    if (!isResend) {
      _resendToken = null;
    }

    try {
      if (kIsWeb) {
        final confirmationResult = await _firebaseAuth.signInWithPhoneNumber(
          normalizedPhone,
        );

        if (requestId != _requestId) {
          return;
        }

        _confirmationResult = confirmationResult;
        return;
      }

      if (defaultTargetPlatform != TargetPlatform.android &&
          defaultTargetPlatform != TargetPlatform.iOS) {
        throw fb.FirebaseAuthException(code: 'unsupported-platform');
      }

      final completer = Completer<void>();

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        forceResendingToken: forceResendingToken,
        verificationCompleted: (credential) async {
          if (requestId != _requestId) {
            return;
          }

          if (_verificationInFlight) {
            return;
          }

          _verificationInFlight = true;

          try {
            await _firebaseAuth.signInWithCredential(credential);

            if (!completer.isCompleted) {
              completer.complete();
            }
          } on Object catch (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
          } finally {
            _verificationInFlight = false;
          }
        },
        verificationFailed: (error) {
          if (requestId != _requestId) {
            return;
          }

          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
        codeSent: (verificationId, resendToken) {
          if (requestId != _requestId) {
            return;
          }

          _verificationId = verificationId;
          _resendToken = resendToken;

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (requestId != _requestId) {
            return;
          }

          _verificationId = verificationId;

          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );

      await completer.future;
    } finally {
      if (requestId == _requestId) {
        _requestInFlight = false;
      }
    }
  }

  @override
  Future<fb.User> verifyOtp({required String code}) async {
    if (_verificationInFlight) {
      throw fb.FirebaseAuthException(code: 'verification-in-progress');
    }

    final normalizedCode = code.trim();

    if (normalizedCode.length != 6) {
      throw fb.FirebaseAuthException(code: 'invalid-verification-code');
    }

    final requestId = _requestId;

    _verificationInFlight = true;

    try {
      final confirmationResult = _confirmationResult;

      if (confirmationResult != null) {
        await confirmationResult.confirm(normalizedCode);
      } else {
        final verificationId = _verificationId;

        if (verificationId == null) {
          throw fb.FirebaseAuthException(code: 'request-new-code');
        }

        final credential = fb.PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: normalizedCode,
        );

        await _firebaseAuth.signInWithCredential(credential);
      }

      if (requestId != _requestId) {
        throw fb.FirebaseAuthException(code: 'session-expired');
      }

      final user = _firebaseAuth.currentUser;

      if (user == null) {
        throw fb.FirebaseAuthException(code: 'verification-failed');
      }

      return user;
    } finally {
      if (requestId == _requestId) {
        _verificationInFlight = false;
      }
    }
  }

  @override
  Future<void> logout() async {
    ++_requestId;

    _clearOtpSession();

    await _firebaseAuth.signOut();
  }

  void _clearOtpSession() {
    _verificationId = null;
    _confirmationResult = null;
    _resendToken = null;
    _currentPhone = '';

    _requestInFlight = false;
    _verificationInFlight = false;
  }
}
