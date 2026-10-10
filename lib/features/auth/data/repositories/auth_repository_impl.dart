import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:async';

import 'package:flutter/foundation.dart';

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
  Stream<AuthChangeEvent> get authStateChanges => _authRemoteDataSource.authStateChanges.transform(
        // OAuth callback failures (cancelled/failed at the provider) surface
        // as stream errors on the Supabase auth stream; map them to stable
        // codes so the cubit can show a localized message.
        StreamTransformer<AuthChangeEvent, AuthChangeEvent>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) =>
              sink.addError(_mapAuthError(error), stackTrace),
        ),
      );

  @override
  Future<User?> getCurrentUser() async {
    final authUser = _authRemoteDataSource.currentUser;

    if (authUser == null) {
      return null;
    }

    final user = await _userRemoteDataSource.getUser(userId: authUser.id);

    if (user != null) {
      return user;
    }

    await _authRemoteDataSource.logout();

    return null;
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
  Future<User> verifyOtp({
    required String code,
    required bool isRegistration,
  }) async {
    try {
      final authUser = await _authRemoteDataSource.verifyOtp(code: code);
      if (isRegistration) {
        final registrationName = _pendingRegistrationName;
        final registrationPhone = _pendingRegistrationPhone;

        if (registrationName == null || registrationName.isEmpty) {
          await _authRemoteDataSource.logout();

          throw const AuthRepositoryException(
            code: 'registration-session-missing',
          );
        }

        final existingUser = await _userRemoteDataSource.getUser(
          userId: authUser.id,
        );

        // print('AUTH DEBUG: Firestore user = $existingUser');
        if (existingUser != null) {
          _clearPendingRegistration();

          return existingUser;
        }

        final user = await _userRemoteDataSource.createUser(
          userId: authUser.id,
          name: registrationName,
          phone: registrationPhone ?? authUser.phone ?? '',
        );

        _clearPendingRegistration();

        return user;
      }

      final existingUser = await _userRemoteDataSource.getUser(
        userId: authUser.id,
      );

      if (existingUser == null) {
        await _authRemoteDataSource.logout();

        throw const AuthRepositoryException(code: 'user-profile-not-found');
      }

      return existingUser;
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final authUser = await _authRemoteDataSource
          .signInWithEmailAndPassword(email: email, password: password);

      final user = await _userRemoteDataSource.getUser(
        userId: authUser.id,
      );

      if (user == null) {
        await _authRemoteDataSource.logout();

        throw const AuthRepositoryException(code: 'user-profile-not-found');
      }

      // Shop-staff sign-in: barbers and the shop owner share this email login.
      // The customer flow (loginCustomerWithEmail) is intentionally unchanged.
      if (user.role != UserRole.barber && user.role != UserRole.owner) {
        await _authRemoteDataSource.logout();

        throw const AuthRepositoryException(code: 'barber-access-denied');
      }

      return user;
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> loginCustomerWithEmail({required String email, required String password}) async {
    try {
      final authUser = await _authRemoteDataSource.signInWithEmailAndPassword(email: email, password: password);
      final user = await _userRemoteDataSource.getUser(userId: authUser.id);
      if (user == null) {
        await _authRemoteDataSource.logout();
        throw const AuthRepositoryException(code: 'user-profile-not-found');
      }
      if (user.role != UserRole.customer) {
        await _authRemoteDataSource.logout();
        throw const AuthRepositoryException(code: 'barber-access-denied');
      }
      return user;
    } on Object catch (error, stackTrace) {
      _logEmailAuthFailure(error, stackTrace);
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User> registerWithEmail({required String name, required String email, required String password}) async {
    try {
      final normalizedName = name.trim();
      final signup = await _authRemoteDataSource.registerWithEmail(email: email, password: password, name: normalizedName);
      final authUser = signup.user;
      debugPrint('[AUTH DEBUG] signUp user=${authUser.id} hasSession=${signup.hasSession}');

      if (!signup.hasSession) {
        // Supabase Auth returned a user without an authenticated session (email
        // confirmation required, or the account already exists). The RLS policy
        // only lets an authenticated user insert their own profile, so never
        // attempt the profiles write from an unauthenticated client.
        final identities = authUser.identities;
        if (identities != null && identities.isEmpty) {
          debugPrint('[AUTH DEBUG] signUp returned an existing account without a session: ${authUser.id}');
          throw const AuthRepositoryException(code: 'account-already-exists');
        }
        debugPrint('[AUTH DEBUG] email confirmation required; skipping profile insert for ${authUser.id}');
        throw const AuthRepositoryException(code: 'email-confirmation-required');
      }

      final existingProfile = await _userRemoteDataSource.getUser(userId: authUser.id);
      if (existingProfile != null) {
        debugPrint('[AUTH DEBUG] profile already exists for ${authUser.id}; skipping insert');
        return existingProfile;
      }
      final profile = await _userRemoteDataSource.createUser(userId: authUser.id, name: normalizedName, phone: '');
      debugPrint('[AUTH DEBUG] created profile id=${profile.id} role=${profile.role} phone=${profile.phone}');
      return profile;
    } on Object catch (error, stackTrace) {
      _logEmailAuthFailure(error, stackTrace);
      throw _mapAuthError(error);
    }
  }

  void _logEmailAuthFailure(Object error, StackTrace stackTrace) {
    if (!kDebugMode || error is AuthRepositoryException) return;
    debugPrint('[AUTH DEBUG] type: ${error.runtimeType}');
    debugPrint('[AUTH DEBUG] message: $error');
    final statusCode = error is AuthException ? error.statusCode : null;
    debugPrint('[AUTH DEBUG] statusCode: ${statusCode ?? 'unavailable'}');
    debugPrint('[AUTH DEBUG] stackTrace:');
    debugPrintStack(stackTrace: stackTrace);
  }

  @override
  Future<void> signInWithProvider(String provider) async {
    try {
      final value = OAuthProvider.values.firstWhere((item) => item.name == provider);
      final launched = await _authRemoteDataSource.signInWithProvider(value);
      if (!launched) throw const AuthRepositoryException(code: 'oauth-cancelled');
    } on Object catch (error) {
      throw _mapAuthError(error);
    }
  }

  @override
  Future<User?> completeSocialSignIn() async {
    final authUser = _authRemoteDataSource.currentUser;
    if (authUser == null) return null;
    try {
      var profile = await _userRemoteDataSource.getUser(userId: authUser.id);
      if (profile == null) {
        final created = DateTime.tryParse(authUser.createdAt)?.toUtc();
        final signedIn = DateTime.tryParse(authUser.lastSignInAt ?? '')?.toUtc();
        final isNewOAuthUser = created != null && signedIn != null && signedIn.difference(created).inSeconds.abs() <= 60;
        if (!isNewOAuthUser) {
          await _authRemoteDataSource.logout();
          throw const AuthRepositoryException(code: 'user-profile-not-found');
        }
        final name = (authUser.userMetadata?['full_name'] ?? authUser.userMetadata?['name'] ?? '').toString();
        profile = await _userRemoteDataSource.createUser(userId: authUser.id, name: name, phone: authUser.phone ?? '');
      }
      return profile;
    } on Object catch (error) {
      if (error is AuthRepositoryException) rethrow;
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

    if (error is AuthException) {
      return AuthRepositoryException(code: _mapAuthCode(error));
    }

    if (_isNetworkFailure(error.toString())) {
      return const AuthRepositoryException(code: 'network-request-failed');
    }

    return const AuthRepositoryException(code: 'generic-auth-error');
  }

  /// Maps a Supabase Auth [AuthException] to a stable app error code.
  ///
  /// The stable Supabase `code` and `statusCode` are checked first; raw
  /// exception messages are only used as a last-resort fallback and are never
  /// surfaced to users.
  String _mapAuthCode(AuthException error) {
    final code = (error.code ?? '').trim().toLowerCase();
    final statusCode = int.tryParse(error.statusCode ?? '') ?? 0;
    final message = error.message.toLowerCase();

    switch (code) {
      // Existing email during registration.
      case 'email_exists':
      case 'user_already_exists':
      case 'identity_already_exists':
        return 'account-already-exists';

      // Invalid credentials during login.
      case 'invalid_credentials':
      case 'invalid login credentials':
      case 'invalid-credential':
      case 'user_not_found':
      case 'user-not-found':
      case 'wrong_password':
      case 'wrong-password':
        return 'invalid-credentials';

      // Email not confirmed before login.
      case 'email_not_confirmed':
      case 'email-not-confirmed':
        return 'email-not-confirmed';

      // Weak password during registration.
      case 'weak_password':
      case 'weak-password':
        return 'weak-password';

      // Rate limit / HTTP 429.
      case 'over_email_send_rate_limit':
      case 'over_sms_send_rate_limit':
      case 'over_request_rate_limit':
      case 'rate_limit_exceeded':
      case 'too_many_requests':
      case '429':
        return 'too-many-requests';

      // Auth service / server failure (HTTP 5xx).
      case 'unexpected_failure':
      case 'internal_error':
      case 'service_unavailable':
        return 'auth-service-unavailable';

      // OAuth provider-side failures reported on the callback redirect.
      case 'server_error':
      case 'temporarily_unavailable':
        return 'auth-service-unavailable';

      // Transport failure raised before an HTTP response was received.
      case 'request_timeout':
        return 'network-request-failed';

      case 'invalid-phone-number':
        return 'invalid-phone-number';

      case 'invalid-verification-code':
      case 'otp_expired':
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

      case 'invalid-email':
        return 'invalid-email';

      case 'access_denied':
      case 'oauth-cancelled':
        return 'oauth-cancelled';

      case 'invalid-password':
        return 'invalid-password';

      case 'user-disabled':
        return 'user-disabled';

      case 'authentication-failed':
        return 'authentication-failed';
    }

    // Stable HTTP status codes when no known code matched.
    if (statusCode == 429) return 'too-many-requests';
    if (statusCode >= 500) return 'auth-service-unavailable';
    if (statusCode == 0 && error is AuthRetryableFetchException) {
      return 'network-request-failed';
    }

    // Message matching only as a fallback.
    if (message.contains('access denied') ||
        message.contains('cancelled') ||
        message.contains('canceled')) {
      return 'oauth-cancelled';
    }
    if (message.contains('rate limit') ||
        message.contains('too many request') ||
        message.contains('too many attempt')) {
      return 'too-many-requests';
    }
    if (message.contains('already registered') ||
        message.contains('already exists')) {
      return 'account-already-exists';
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('wrong password') ||
        (message.contains('email') &&
            message.contains('password') &&
            (message.contains('invalid') || message.contains('incorrect')))) {
      return 'invalid-credentials';
    }
    if (message.contains('email not confirmed') ||
        message.contains('not confirmed')) {
      return 'email-not-confirmed';
    }
    if (message.contains('weak password') ||
        (message.contains('password') && message.contains('at least'))) {
      return 'weak-password';
    }
    if (message.contains('invalid email') ||
        (message.contains('email') &&
            message.contains('invalid') &&
            message.contains('format'))) {
      return 'invalid-email';
    }
    if (_isNetworkFailure(message)) return 'network-request-failed';

    return 'generic-auth-error';
  }

  bool _isNetworkFailure(String description) {
    final value = description.toLowerCase();
    return value.contains('socketexception') ||
        value.contains('clientexception') ||
        value.contains('handshakeexception') ||
        value.contains('failed host lookup') ||
        value.contains('unable to resolve') ||
        value.contains('connection refused') ||
        value.contains('connection reset') ||
        value.contains('connection closed') ||
        value.contains('connection error') ||
        value.contains('connection timed out') ||
        value.contains('network is unreachable') ||
        value.contains('network request failed');
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
