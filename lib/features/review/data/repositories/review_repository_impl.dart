import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  ReviewRepositoryImpl(this._dataSource);

  final ReviewRemoteDataSource _dataSource;

  @override
  Future<({List<MyReviewEntity> reviews, int total})> getMyReviews({
    int limit = 50,
    int skip = 0,
  }) async {
    final result = await _dataSource.getMyReviews(limit: limit, skip: skip);
    return (
      reviews: result.reviews
          .map((dto) => MyReviewEntity(
                id: dto.id,
                productId: dto.productId,
                rating: dto.rating,
                title: dto.title,
                comment: dto.comment,
                productName: dto.productName,
                productImage: dto.productImage,
                createdAt: dto.createdAt,
              ))
          .toList(),
      total: result.total,
    );
  }

  @override
  Future<({List<ProductReviewEntity> reviews, int total})> getProductReviews(
    String productId, {
    int limit = 20,
    int skip = 0,
  }) async {
    final result = await _dataSource.getProductReviews(productId, limit: limit, skip: skip);
    return (
      reviews: result.reviews
          .map((dto) => ProductReviewEntity(
                id: dto.id,
                userName: dto.userName,
                rating: dto.rating,
                title: dto.title,
                comment: dto.comment,
                createdAt: dto.createdAt,
              ))
          .toList(),
      total: result.total,
    );
  }

  @override
  Future<void> submitReview({
    required String productId,
    required int rating,
    required String title,
    required String comment,
    List<String>? images,
  }) =>
      _dataSource.submitReview(
        productId: productId,
        rating: rating,
        title: title,
        comment: comment,
        images: images,
      );

  @override
  Future<void> updateReview({
    required String productId,
    required String reviewId,
    required String title,
    required String comment,
    List<String>? images,
  }) =>
      _dataSource.updateReview(
        productId: productId,
        reviewId: reviewId,
        title: title,
        comment: comment,
        images: images,
      );

  @override
  Future<void> deleteReview({
    required String productId,
    required String reviewId,
  }) =>
      _dataSource.deleteReview(productId: productId, reviewId: reviewId);

  @override
  Future<void> markHelpful({
    required String productId,
    required String reviewId,
  }) =>
      _dataSource.markHelpful(productId: productId, reviewId: reviewId);
}
