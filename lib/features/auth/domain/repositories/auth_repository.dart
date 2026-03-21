import '../entities/auth_result.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<AuthResult> login(String email, String password);
  Future<AuthResult> register(String email, String password, String name);
  Future<void> logout();
  Future<UserEntity?> getMe();
  Future<AuthResult?> refresh();
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
  });
}
