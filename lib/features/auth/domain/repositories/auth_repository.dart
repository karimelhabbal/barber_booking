import '../entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent;

abstract interface class AuthRepository {
  Stream<AuthChangeEvent> get authStateChanges;
  Future<User?> getCurrentUser();

  Future<void> sendLoginOtp({required String phone});

  Future<void> sendRegistrationOtp({
    required String name,
    required String phone,
  });

  Future<void> resendOtp();

  Future<User> verifyOtp({required String code, required bool isRegistration});

  Future<User> loginWithEmail({
    required String email,
    required String password,
  });
  Future<User> loginCustomerWithEmail({required String email, required String password});

  Future<User> registerWithEmail({required String name, required String email, required String password});
  Future<void> signInWithProvider(String provider);
  Future<User?> completeSocialSignIn();

  Future<void> logout();
}
