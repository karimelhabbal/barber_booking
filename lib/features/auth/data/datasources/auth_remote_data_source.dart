import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of an email sign-up attempt.
///
/// [hasSession] is `false` when the Supabase project requires email
/// confirmation before an authenticated session is issued, which means the
/// client cannot read/write `public.profiles` yet (RLS requires `authenticated`).
class AuthSignupResult {
  const AuthSignupResult({required this.user, required this.hasSession});

  final User user;
  final bool hasSession;
}

abstract interface class AuthRemoteDataSource {
  User? get currentUser;
  Stream<AuthChangeEvent> get authStateChanges;
  Future<void> sendLoginOtp({required String phone});
  Future<void> sendRegistrationOtp({required String name, required String phone});
  Future<void> resendOtp();
  Future<User> verifyOtp({required String code});
  Future<User> signInWithEmailAndPassword({required String email, required String password});
  Future<AuthSignupResult> registerWithEmail({required String email, required String password, required String name});
  Future<bool> signInWithProvider(OAuthProvider provider);
  Future<void> logout();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({required this._client});
  final SupabaseClient _client;
  String? _phone;

  @override
  User? get currentUser => _client.auth.currentUser;
  @override
  Stream<AuthChangeEvent> get authStateChanges => _client.auth.onAuthStateChange.map((event) => event.event);

  @override
  Future<void> sendLoginOtp({required String phone}) => _sendOtp(phone, false);

  @override
  Future<void> sendRegistrationOtp({required String name, required String phone}) => _sendOtp(phone, true);

  Future<void> _sendOtp(String phone, bool shouldCreateUser) async {
    final normalized = phone.trim();
    if (normalized.isEmpty) throw const AuthException('Invalid phone number', code: 'invalid-phone-number');
    _phone = normalized;
    await _client.auth.signInWithOtp(phone: normalized, shouldCreateUser: shouldCreateUser);
  }

  @override
  Future<void> resendOtp() async {
    final phone = _phone;
    if (phone == null) throw const AuthException('Request a code first', code: 'request-new-code');
    await _client.auth.resend(type: OtpType.sms, phone: phone);
  }

  @override
  Future<User> verifyOtp({required String code}) async {
    final phone = _phone;
    if (phone == null) throw const AuthException('Request a code first', code: 'request-new-code');
    final response = await _client.auth.verifyOTP(phone: phone, token: code.trim(), type: OtpType.sms);
    final user = response.user;
    if (user == null) throw const AuthException('Authentication failed', code: 'authentication-failed');
    return user;
  }

  @override
  Future<User> signInWithEmailAndPassword({required String email, required String password}) async {
    if (email.trim().isEmpty) throw const AuthException('Invalid email', code: 'invalid-email');
    if (password.isEmpty) throw const AuthException('Invalid password', code: 'invalid-password');
    final response = await _client.auth.signInWithPassword(email: email.trim(), password: password);
    final user = response.user;
    if (user == null) throw const AuthException('Authentication failed', code: 'authentication-failed');
    return user;
  }

  @override
  Future<AuthSignupResult> registerWithEmail({required String email, required String password, required String name}) async {
    final response = await _client.auth.signUp(email: email.trim(), password: password, data: {'name': name.trim()});
    final user = response.user;
    if (user == null) throw const AuthException('Authentication failed', code: 'authentication-failed');
    return AuthSignupResult(user: user, hasSession: response.session != null);
  }

  @override
  Future<bool> signInWithProvider(OAuthProvider provider) => _client.auth.signInWithOAuth(
    provider,
    redirectTo: 'io.supabase.flutter://login-callback/',
  );

  @override
  Future<void> logout() async {
    _phone = null;
    await _client.auth.signOut();
  }
}
