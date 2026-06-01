import '../repositories/auth_repository.dart';

class ForgotPasswordUseCase {
  ForgotPasswordUseCase(this._repo);

  final AuthRepository _repo;

  Future<void> call(String email) => _repo.forgotPassword(email);
}
