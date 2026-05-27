import 'dart:io';

import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  UpdateProfileUseCase(this._repository);
  final AuthRepository _repository;

  Future<void> call({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
    String? avatar,
    String? city,
  }) =>
      _repository.updateProfile(
        name: name,
        email: email,
        phone: phone,
        birthday: birthday,
        avatar: avatar,
        city: city,
      );

  Future<String> uploadAvatar(File file) => _repository.uploadAvatar(file);
}
