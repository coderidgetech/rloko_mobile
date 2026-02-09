import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call(String email, String password, String name) =>
      _repository.register(email, password, name);
}
