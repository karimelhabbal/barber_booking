// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';

// import '../../auth_cubit.dart';
// import '../../data/repositories/auth_repository_impl.dart';

// import '../../domain/entities/user.dart';
// import '../../domain/repositories/auth_repository.dart';

// part 'auth_state.dart';

// class AuthCubit extends Cubit<AuthState> {
//   AuthCubit({required AuthRepository authRepository})
//     : _authRepository = authRepository,
//       super(AuthInitial()) {
//     _restoreSession();
//   }

//   final AuthRepository _authRepository;

//   Future<void> _restoreSession() async {
//     final user = _authRepository.currentUser;

//     if (user != null) {
//       emit(AuthAuthenticated(user));
//     }
//   }

//   Future<void> loginWithPhone({required String phone}) async {
//     if (state is AuthLoading) {
//       return;
//     }

//     emit(AuthLoading());

//     try {
//       await _authRepository.sendLoginOtp(phone: phone);

//       emit(AuthCodeSent(phone.trim()));
//     } on Object catch (error) {
//       emit(AuthError(_mapError(error)));
//     }
//   }

//   Future<void> register({required String name, required String phone}) async {
//     if (state is AuthLoading) {
//       return;
//     }

//     emit(AuthLoading());

//     try {
//       await _authRepository.sendRegistrationOtp(name: name, phone: phone);

//       emit(AuthCodeSent(phone.trim()));
//     } on Object catch (error) {
//       emit(AuthError(_mapError(error)));
//     }
//   }

//   Future<void> resendOtp() async {
//     if (state is AuthLoading) {
//       return;
//     }

//     final previousState = state;

//     if (previousState is! AuthCodeSent) {
//       emit(const AuthError('request-new-code'));
//       return;
//     }

//     final phoneNumber = previousState.phoneNumber;

//     emit(const AuthLoading());

//     try {
//       await _authRepository.resendOtp();

//       emit(AuthCodeSent(phoneNumber));
//     } on Object catch (error) {
//       emit(AuthError(_mapError(error)));
//     }
//   }

//   Future<void> verifyOtp({required String code}) async {
//     if (state is AuthLoading) {
//       return;
//     }

//     emit(AuthLoading());

//     try {
//       final user = await _authRepository.verifyOtp(code: code);

//       emit(AuthAuthenticated(user));
//     } on Object catch (error) {
//       emit(AuthError(_mapError(error)));
//     }
//   }

//   Future<void> logout() async {
//     if (state is AuthLoading) {
//       return;
//     }

//     emit(AuthLoading());

//     try {
//       await _authRepository.logout();

//       emit(AuthUnauthenticated());
//     } on Object catch (error) {
//       emit(AuthError(_mapError(error)));
//     }
//   }

//   String _mapError(Object error) {
//     if (error is AuthRepositoryException) {
//       return error.code;
//     }

//     // FirebaseAuthException is intentionally not imported here.
//     // Firebase-specific errors should be mapped inside the data layer
//     // in a later step so the presentation layer remains Firebase-free.

//     return 'generic-auth-error';
//   }
// }

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this._authRepository}) : super(const AuthLoading()) {
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
