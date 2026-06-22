import 'dart:io';

import '../repositories/review_repository.dart';

/// Uploads a single review photo and returns its stored URL.
class UploadReviewImageUseCase {
  UploadReviewImageUseCase(this._repository);

  final ReviewRepository _repository;

  Future<String> call(File file) => _repository.uploadImage(file);
}
