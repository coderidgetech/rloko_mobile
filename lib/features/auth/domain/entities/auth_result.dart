import 'package:equatable/equatable.dart';

import 'user_entity.dart';

class AuthResult extends Equatable {
  const AuthResult({required this.user, this.token});

  final UserEntity user;
  final String? token;

  @override
  List<Object?> get props => [user, token];
}
