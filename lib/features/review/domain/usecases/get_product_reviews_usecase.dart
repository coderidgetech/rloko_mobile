import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

class GetProductReviewsUseCase {
  GetProductReviewsUseCase(this._repository);

  final ReviewRepository _repository;

  Future<({List<ProductReviewEntity> reviews, int total})> call(
    String productId, {
    int limit = 20,
    int skip = 0,
  }) =>
      _repository.getProductReviews(productId, limit: limit, skip: skip);
}
