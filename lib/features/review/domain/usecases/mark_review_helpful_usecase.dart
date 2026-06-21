import '../repositories/review_repository.dart';

class MarkReviewHelpfulUseCase {
  MarkReviewHelpfulUseCase(this._repository);

  final ReviewRepository _repository;

  Future<void> call({required String productId, required String reviewId}) =>
      _repository.markHelpful(productId: productId, reviewId: reviewId);
}
