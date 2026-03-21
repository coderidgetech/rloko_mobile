import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
  }) =>
      _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
        birthday: birthday,
      );
}
