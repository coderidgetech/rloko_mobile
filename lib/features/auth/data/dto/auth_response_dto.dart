import 'user_dto.dart';

class AuthResponseDto {
  AuthResponseDto({required this.user, this.token});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    // Backend may send "token" or "auth_token"
    final token = json['token'] as String? ?? json['auth_token'] as String?;
    // Backend may send nested "user" or user fields at top level (e.g. { id, email, name, token })
    final userMap = json['user'] as Map<String, dynamic>?;
    final userJson = userMap ?? json;
    return AuthResponseDto(
      user: UserDto.fromJson(Map<String, dynamic>.from(userJson)),
      token: token,
    );
  }

  final UserDto user;
  final String? token;
}
