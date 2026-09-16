import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._authRepository})
    : super(const AuthCheckingSession()) {
    _restoreSession();
  }

  final AuthRepository _authRepository;

  Future<void> _restoreSession() async {
    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> loginWithPhone({required String phone}) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.sendLoginOtp(phone: phone);

      emit(AuthCodeSent(phone.trim()));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      final user = await _authRepository.loginWithEmail(
        email: email,
        password: password,
      );

      emit(AuthAuthenticated(user));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> register({required String name, required String phone}) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.sendRegistrationOtp(name: name, phone: phone);

      emit(AuthCodeSent(phone.trim()));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> resendOtp() async {
    if (state is AuthLoading) {
      return;
    }

    final previousState = state;

    if (previousState is! AuthCodeSent) {
      emit(const AuthError('request-new-code'));
      return;
    }

    final phoneNumber = previousState.phoneNumber;

    emit(const AuthLoading());

    try {
      await _authRepository.resendOtp();

      emit(AuthCodeSent(phoneNumber));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> verifyOtp({required String code}) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      final user = await _authRepository.verifyOtp(code: code);

      emit(AuthAuthenticated(user));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> logout() async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.logout();

      emit(const AuthUnauthenticated());
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  String _mapError(Object error) {
    if (error is AuthRepositoryException) {
      return error.code;
    }

    return 'generic-auth-error';
  }
}
