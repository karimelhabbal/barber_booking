part of 'auth_cubit.dart';

enum AuthMode { login, register }

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

/// حالة فحص جلسة Firebase عند تشغيل التطبيق.
class AuthCheckingSession extends AuthState {
  const AuthCheckingSession();
}

/// حالة تنفيذ عملية مثل إرسال OTP أو التحقق أو تسجيل الخروج.
class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthCodeSent extends AuthState {
  const AuthCodeSent({required this.phoneNumber, required this.mode});

  final String phoneNumber;
  final AuthMode mode;

  @override
  List<Object?> get props => [phoneNumber, mode];
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}
