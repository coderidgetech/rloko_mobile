import '../repositories/review_repository.dart';

class UpdateReviewUseCase {
  UpdateReviewUseCase(this._repository);

  final ReviewRepository _repository;

  Future<void> call({
    required String productId,
    required String reviewId,
    required String title,
    required String comment,
    List<String>? images,
  }) =>
      _repository.updateReview(
        productId: productId,
        reviewId: reviewId,
        title: title,
        comment: comment,
        images: images,
      );
}
