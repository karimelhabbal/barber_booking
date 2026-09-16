import '../entities/user.dart';

abstract interface class AuthRepository {
  Future<User?> getCurrentUser();

  Future<void> sendLoginOtp({required String phone});

  Future<void> sendRegistrationOtp({
    required String name,
    required String phone,
  });

  Future<void> resendOtp();

  Future<User> verifyOtp({required String code});

  Future<User> loginWithEmail({
    required String email,
    required String password,
  });

  Future<void> logout();
}
