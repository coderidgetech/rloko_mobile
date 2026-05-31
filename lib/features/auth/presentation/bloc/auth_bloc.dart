import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/complete_login_otp_usecase.dart';
import '../../domain/usecases/get_me_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/login_with_google_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required LoginUseCase loginUseCase,
    required CompleteLoginOtpUseCase completeLoginOtpUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterUseCase registerUseCase,
    required LogoutUseCase logoutUseCase,
    required GetMeUseCase getMeUseCase,
  })  : _loginUseCase = loginUseCase,
        _completeLoginOtpUseCase = completeLoginOtpUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _registerUseCase = registerUseCase,
        _logoutUseCase = logoutUseCase,
        _getMeUseCase = getMeUseCase,
        super(const AuthLoading()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthCompleteLoginOtpRequested>(_onCompleteLoginOtpRequested);
    on<AuthLoginWithGoogleRequested>(_onLoginWithGoogleRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckRequested>(_onCheckRequested);
    add(const AuthCheckRequested());
  }

  final LoginUseCase _loginUseCase;
  final CompleteLoginOtpUseCase _completeLoginOtpUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;
  final GetMeUseCase _getMeUseCase;

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

  Future<void> _onCompleteLoginOtpRequested(
    AuthCompleteLoginOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _completeLoginOtpUseCase(event.phone, event.code);
      emit(AuthAuthenticated(result.user));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AuthBloc] completeLoginOtp failed: $e\n$st');
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onLoginWithGoogleRequested(
    AuthLoginWithGoogleRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final result = await _loginWithGoogleUseCase(event.idToken);
      emit(AuthAuthenticated(result.user));
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AuthBloc] Google sign-in failed: $e\n$st');
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
    } catch (e, st) {
      if (kDebugMode) debugPrint('[AuthBloc] register failed: $e\n$st');
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
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthBloc] AuthCheck: could not restore session ($e)');
      }
      emit(const AuthUnauthenticated());
    }
  }
}
