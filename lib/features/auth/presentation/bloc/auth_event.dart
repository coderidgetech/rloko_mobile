part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthCompleteLoginOtpRequested extends AuthEvent {
  const AuthCompleteLoginOtpRequested({
    required this.phone,
    required this.code,
  });

  final String phone;
  final String code;

  @override
  List<Object?> get props => [phone, code];
}

final class AuthLoginWithGoogleRequested extends AuthEvent {
  const AuthLoginWithGoogleRequested(this.idToken);

  final String idToken;

  @override
  List<Object?> get props => [idToken];
}

final class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  final String email;
  final String password;
  final String name;

  @override
  List<Object?> get props => [email, password, name];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}
