import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<({List<MyReviewEntity> reviews, int total})> getMyReviews({int limit = 50, int skip = 0});
  Future<({List<ProductReviewEntity> reviews, int total})> getProductReviews(
    String productId, {
    int limit = 20,
    int skip = 0,
  });
  Future<void> submitReview({
    required String productId,
    required int rating,
    required String title,
    required String comment,
  });
}
