import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetMeUseCase getMeUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getMeUseCase = getMeUseCase,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
  }

  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetMeUseCase _getMeUseCase;

  /// True when we should try restoring session from stored token (e.g. on app resume).
  bool get shouldTryRestoreFromToken => state is AuthUnauthenticated;

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _loginUseCase(event.email, event.password);
      if (kDebugMode) {
        final u = result.user;
        debugPrint('[AuthBloc] Login success');
        debugPrint('[AuthBloc] Response: id=${u.id}, email=${u.email}, name=${u.name}, role=${u.role}, '
            'token=${result.token != null ? "${result.token!.substring(0, 30)}..." : null}');
      }
      emit(AuthAuthenticated(result.user));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AuthBloc] Login failed: $e\n$st');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _registerUseCase(
        event.email,
        event.password,
        event.name,
      );
      emit(AuthAuthenticated(result.user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _logoutUseCase();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _getMeUseCase();
      if (kDebugMode) {
        debugPrint('[AuthBloc] AuthCheck: user=${user?.email ?? "null"}');
      }
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AuthBloc] AuthCheck failed: $e\n$st');
      }
      emit(const AuthUnauthenticated());
    }
  }
}
