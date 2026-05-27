import '../dto/my_review_dto.dart';
import '../dto/product_review_dto.dart';
import '../../../../core/network/dio_client.dart';

class ReviewRemoteDataSource {
  ReviewRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<({List<MyReviewDto> reviews, int total})> getMyReviews({int limit = 50, int skip = 0}) async {
    final response = await _dio.get<dynamic>(
      '/reviews/me',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    final data = response.data;
    if (data is! Map) {
      return (reviews: <MyReviewDto>[], total: 0);
    }
    final raw = data['reviews'];
    if (raw is! List) {
      return (reviews: <MyReviewDto>[], total: 0);
    }
    final list = raw
        .map((e) => MyReviewDto.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] is int) ? data['total'] as int : list.length;
    return (reviews: list, total: total);
  }

  /// GET /products/:id/reviews — approved reviews for product detail.
  Future<({List<ProductReviewDto> reviews, int total})> getProductReviews(
    String productId, {
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '/products/$productId/reviews',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    final data = response.data;
    if (data is! Map) {
      return (reviews: <ProductReviewDto>[], total: 0);
    }
    final raw = data['reviews'];
    if (raw is! List) {
      return (reviews: <ProductReviewDto>[], total: 0);
    }
    final list = raw
        .map((e) => ProductReviewDto.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
    final total = (data['total'] is int) ? data['total'] as int : list.length;
    return (reviews: list, total: total);
  }

  /// POST /products/:id/reviews
  Future<void> submitReview({
    required String productId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    await _dio.post<dynamic>(
      '/products/$productId/reviews',
      data: {'rating': rating, 'title': title, 'comment': comment},
    );
  }
}
