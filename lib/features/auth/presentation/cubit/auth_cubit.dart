import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSub;

  AuthCubit({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    _checkAuthStatus();
    
    _authSub = _repository.authStateChanges().listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> _checkAuthStatus() async {
    emit(AuthLoading());
    try {
      final user = await _repository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> signInDemoAsRole(String role) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signInDemoAsRole(role);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _repository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(Unauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSub?.cancel();
    return super.close();
  }
}
