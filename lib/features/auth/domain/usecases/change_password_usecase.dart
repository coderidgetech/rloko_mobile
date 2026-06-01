import '../repositories/auth_repository.dart';

class ChangePasswordUseCase {
  ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String currentPassword, String newPassword) =>
      _repository.changePassword(currentPassword, newPassword);
}
