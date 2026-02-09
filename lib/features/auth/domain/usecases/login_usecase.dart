import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call(String email, String password) =>
      _repository.login(email, password);
}
