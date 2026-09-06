import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/user_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this._authRemoteDataSource,
    required this._userRemoteDataSource,
  });

  final AuthRemoteDataSource _authRemoteDataSource;
  final UserRemoteDataSource _userRemoteDataSource;

  String? _pendingRegistrationName;
  String? _pendingRegistrationPhone;
  @override
  Future<User?> getCurrentUser() async {
    final firebaseUser = _authRemoteDataSource.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final user = await _userRemoteDataSource.getUser(userId: firebaseUser.uid);

    if (user != null) {
      return user;
    }

    return User(id: firebaseUser.uid, phone: firebaseUser.phoneNumber);
  }

  @override
  Future<void> sendLoginOtp({required String phone}) async {
    _clearPendingRegistration();

    try {
      await _authRemoteDataSource.sendLoginOtp(phone: phone);
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<void> sendRegistrationOtp({
    required String name,
    required String phone,
  }) async {
    final normalizedName = name.trim();
    final normalizedPhone = phone.trim();

    if (normalizedName.isEmpty) {
      throw const AuthRepositoryException(code: 'invalid-name');
    }

    if (normalizedPhone.isEmpty) {
      throw const AuthRepositoryException(code: 'invalid-phone-number');
    }

    _pendingRegistrationName = normalizedName;
    _pendingRegistrationPhone = normalizedPhone;

    try {
      await _authRemoteDataSource.sendRegistrationOtp(
        name: normalizedName,
        phone: normalizedPhone,
      );
    } on Object catch (error) {
      _clearPendingRegistration();
      throw _mapAuthError(error);
    }
  }

  @override
  Future<void> resendOtp() async {
    try {
      await _authRemoteDataSource.resendOtp();
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> verifyOtp({required String code}) async {
    try {
      final firebaseUser = await _authRemoteDataSource.verifyOtp(code: code);

      final registrationName = _pendingRegistrationName;
      final registrationPhone = _pendingRegistrationPhone;

      if (registrationName != null && registrationName.isNotEmpty) {
        final user = await _userRemoteDataSource.createUser(
          userId: firebaseUser.uid,
          name: registrationName,
          phone: registrationPhone ?? firebaseUser.phoneNumber ?? '',
        );

        _clearPendingRegistration();

        return user;
      }

      final existingUser = await _userRemoteDataSource.getUser(
        userId: firebaseUser.uid,
      );

      if (existingUser != null) {
        return existingUser;
      }

      return await _userRemoteDataSource.createUser(
        userId: firebaseUser.uid,
        name: '',
        phone: firebaseUser.phoneNumber ?? '',
      );
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<void> logout() async {
    _clearPendingRegistration();

    try {
      await _authRemoteDataSource.logout();
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  AuthRepositoryException _mapAuthError(Object error) {
    if (error is AuthRepositoryException) {
      return error;
    }

    if (error is fb.FirebaseAuthException) {
      return AuthRepositoryException(code: _mapFirebaseAuthCode(error.code));
    }

    return const AuthRepositoryException(code: 'generic-auth-error');
  }

  String _mapFirebaseAuthCode(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'invalid-phone-number';

      case 'invalid-verification-code':
        return 'invalid-verification-code';

      case 'session-expired':
        return 'session-expired';

      case 'too-many-requests':
        return 'too-many-requests';

      case 'network-request-failed':
        return 'network-request-failed';

      case 'operation-not-allowed':
        return 'operation-not-allowed';

      case 'unauthorized-domain':
        return 'unauthorized-domain';

      case 'captcha-check-failed':
      case 'missing-app-credential':
        return 'captcha-check-failed';

      case 'verification-in-progress':
        return 'verification-in-progress';

      case 'request-new-code':
        return 'request-new-code';

      case 'unsupported-platform':
        return 'unsupported-platform';

      default:
        return 'generic-auth-error';
    }
  }

  void _clearPendingRegistration() {
    _pendingRegistrationName = null;
    _pendingRegistrationPhone = null;
  }
}

class AuthRepositoryException implements Exception {
  const AuthRepositoryException({required this.code});

  final String code;

  @override
  String toString() => 'AuthRepositoryException($code)';
}
