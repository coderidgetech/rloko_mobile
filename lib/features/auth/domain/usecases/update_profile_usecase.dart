import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({String? phone, DateTime? birthday}) =>
      _repository.updateProfile(phone: phone, birthday: birthday);
}
