import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  StreamSubscription<bool>? _sub;

  AuthCubit(this._repo) : super(const AuthState()) {
    _sub = _repo.authStateChanges().listen((signedIn) {
      if (isClosed) return;
      emit(state.copyWith(
        status: signedIn
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: _repo.currentUser,
      ));
    });
  }

  Future<void> signInWithGoogle() async {
    if (isClosed) return;
    emit(state.copyWith(submitting: true, error: null));
    try {
      await _repo.signInWithGoogle();
      // Sign-in success flips authStateChanges, which may close this cubit
      // (the /login route is torn down) before we get here.
      if (isClosed) return;
      emit(state.copyWith(submitting: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }

  Future<void> signOut() => _repo.signOut();

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
