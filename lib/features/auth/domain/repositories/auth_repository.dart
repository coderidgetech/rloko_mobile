import 'dart:io';

import '../entities/auth_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<void> sendLoginOtp(String phone);
  Future<AuthResult> completeLoginOtp(String phone, String code);
  Future<AuthResult> loginWithGoogle(String idToken);
  Future<AuthResult> register(String email, String password, String name);
  Future<void> logout();
  Future<UserEntity?> getMe();
  Future<AuthResult?> refresh();
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
    String? avatar,
    String? city,
  });
  Future<String> uploadAvatar(File file);
  Future<void> changePassword(String currentPassword, String newPassword);
  Future<void> forgotPassword(String email);
}
