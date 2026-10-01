import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._authRepository, required this._notificationsCubit})
    : super(const AuthCheckingSession()) {
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final NotificationsCubit _notificationsCubit;

  Future<void> _restoreSession() async {
    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user));
        await _startNotifications(user);
      } else {
        emit(const AuthUnauthenticated());
      }
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  /// Starts the notification session for [user] without ever breaking auth.
  Future<void> _startNotifications(User user) async {
    try {
      await _notificationsCubit.start(
        userId: user.id,
        role: user.role,
        shopId: user.barberShopId,
      );
    } on Object catch (_) {
      // Push registration failures must not affect authentication.
    }
  }

  Future<void> loginWithPhone({required String phone}) async {
    if (state is AuthLoading) {
      return;
    }

    emit(const AuthLoading());

    try {
      await _authRepository.sendLoginOtp(phone: phone);

      emit(AuthCodeSent(phoneNumber: phone.trim(), mode: AuthMode.login));
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
      await _startNotifications(user);
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

      emit(AuthCodeSent(phoneNumber: phone.trim(), mode: AuthMode.register));
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
    final mode = previousState.mode;

    emit(const AuthLoading());

    try {
      await _authRepository.resendOtp();

      emit(AuthCodeSent(phoneNumber: phoneNumber, mode: mode));
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> verifyOtp({required String code}) async {
    if (state is AuthLoading) {
      return;
    }

    final currentState = state;

    if (currentState is! AuthCodeSent) {
      emit(const AuthError('request-new-code'));
      return;
    }

    final isRegistration = currentState.mode == AuthMode.register;

    emit(const AuthLoading());

    try {
      final user = await _authRepository.verifyOtp(
        code: code,
        isRegistration: isRegistration,
      );

      emit(AuthAuthenticated(user));
      await _startNotifications(user);
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
      // Stop notifications and drop this device's token BEFORE signing out,
      // otherwise the previous account could keep receiving pushes here.
      await _notificationsCubit.stop();

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
