import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import '../../../notifications/presentation/cubit/notifications_cubit.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._authRepository, required this._notificationsCubit})
    : super(const AuthCheckingSession()) {
    _authSubscription = _authRepository.authStateChanges.listen(
      (event) {
        if (_awaitingOAuth && event == supa.AuthChangeEvent.signedIn) {
          _finishOAuth();
        }
      },
      onError: (Object error) {
        // OAuth callback failures (cancelled or failed at the provider) arrive
        // as stream errors; surface them through the existing error mapping.
        if (!_awaitingOAuth || isClosed) return;
        _awaitingOAuth = false;
        emit(AuthError(_mapError(error)));
      },
    );
    _restoreSession();
  }

  final AuthRepository _authRepository;
  final NotificationsCubit _notificationsCubit;
  late final StreamSubscription<dynamic> _authSubscription;
  bool _awaitingOAuth = false;

  Future<void> _finishOAuth() async {
    _awaitingOAuth = false;
    try {
      final user = await _authRepository.completeSocialSignIn();
      if (user == null || isClosed) return;
      emit(AuthAuthenticated(user));
      await _startNotifications(user);
    } on Object catch (error) {
      if (!isClosed) emit(AuthError(_mapError(error)));
    }
  }

  Future<void> signInWithProvider(String provider) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    _awaitingOAuth = true;
    try {
      await _authRepository.signInWithProvider(provider);
      if (state is AuthLoading) emit(const AuthUnauthenticated());
    } on Object catch (error) {
      _awaitingOAuth = false;
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      final user = await _authRepository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      await _startNotifications(user);
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

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
      try {
        await _notificationsCubit.stop();
      } on Object catch (_) {
        // Notification cleanup is best effort.
      }

      await _authRepository.logout();

      emit(const AuthUnauthenticated());
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  Future<void> loginCustomerWithEmail({
    required String email,
    required String password,
  }) async {
    if (state is AuthLoading) return;
    emit(const AuthLoading());
    try {
      final user = await _authRepository.loginCustomerWithEmail(
        email: email,
        password: password,
      );
      emit(AuthAuthenticated(user));
      await _startNotifications(user);
    } on Object catch (error) {
      emit(AuthError(_mapError(error)));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription.cancel();
    return super.close();
  }

  String _mapError(Object error) {
    if (error is AuthRepositoryException) {
      return error.code;
    }

    return 'generic-auth-error';
  }
}
