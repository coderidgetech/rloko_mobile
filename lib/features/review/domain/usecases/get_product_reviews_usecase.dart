import '../../data/datasources/review_remote_datasource.dart';
import '../../data/dto/product_review_dto.dart';

class GetProductReviewsUseCase {
  GetProductReviewsUseCase(this._data);

  final ReviewRemoteDataSource _data;

  Future<({List<ProductReviewDto> reviews, int total})> call(
    String productId, {
    int limit = 20,
    int skip = 0,
  }) =>
      _data.getProductReviews(productId, limit: limit, skip: skip);
}
