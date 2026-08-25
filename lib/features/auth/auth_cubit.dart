import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  AuthCubit() : super(AuthInitial());

  Future<void> loginWithPhone({required String phone}) async {
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
    emit(AuthLoading());
    try {
      await _auth.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
