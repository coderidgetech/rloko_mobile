import '../entities/auth_result.dart';
import '../repositories/auth_repository.dart';

class LoginWithGoogleUseCase {
  LoginWithGoogleUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthResult> call(String idToken) =>
      _repository.loginWithGoogle(idToken);
}
