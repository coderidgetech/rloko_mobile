import '../repositories/review_repository.dart';

class SubmitReviewUseCase {
  SubmitReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<void> call({
    required String productId,
    required int rating,
    required String title,
    required String comment,
  }) =>
      _repository.submitReview(
        productId: productId,
        rating: rating,
        title: title,
        comment: comment,
      );
}
