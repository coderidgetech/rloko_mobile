import '../repositories/review_repository.dart';

class DeleteReviewUseCase {
  DeleteReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<void> call({required String productId, required String reviewId}) =>
      _repository.deleteReview(productId: productId, reviewId: reviewId);
}
