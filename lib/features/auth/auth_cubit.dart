import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart' as firebase_core;

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  fb.FirebaseAuth? get _auth => firebase_core.Firebase.apps.isNotEmpty ? fb.FirebaseAuth.instance : null;

  Future<void> loginWithPhone({required String phone}) async {
    final auth = _auth;
    if (auth == null) {
      emit(AuthAuthenticated());
      return;
    }

    emit(AuthLoading());
    try {
      // Note: implement real phone flow with verificationId/credential in production.
      // Here we just simulate success if a user exists.
      // TODO: implement real phone auth (SMS verification)
      await Future.delayed(const Duration(seconds: 1));
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> register({required String name, required String phone}) async {
    final auth = _auth;
    if (auth == null) {
      emit(AuthAuthenticated());
      return;
    }

    emit(AuthLoading());
    try {
      // TODO: create user record in Firestore and link auth method
      await Future.delayed(const Duration(milliseconds: 500));
      emit(AuthAuthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    final auth = _auth;
    if (auth == null) {
      emit(AuthUnauthenticated());
      return;
    }

    emit(AuthLoading());
    try {
      await auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
