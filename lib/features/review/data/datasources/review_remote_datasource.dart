import 'dart:io';

import 'package:dio/dio.dart';

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
    List<String>? images,
  }) async {
    await _dio.post<dynamic>(
      '/products/$productId/reviews',
      data: {
        'rating': rating,
        'title': title,
        'comment': comment,
        if (images != null && images.isNotEmpty) 'images': images,
      },
    );
  }

  /// PUT /products/:id/reviews/:reviewId
  Future<void> updateReview({
    required String productId,
    required String reviewId,
    required String title,
    required String comment,
    List<String>? images,
  }) async {
    await _dio.put<dynamic>(
      '/products/$productId/reviews/$reviewId',
      data: {
        'title': title,
        'comment': comment,
        if (images != null) 'images': images,
      },
    );
  }

  /// DELETE /products/:id/reviews/:reviewId
  Future<void> deleteReview({
    required String productId,
    required String reviewId,
  }) async {
    await _dio.delete<dynamic>('/products/$productId/reviews/$reviewId');
  }

  /// POST /products/:id/reviews/:reviewId/helpful
  Future<void> markHelpful({
    required String productId,
    required String reviewId,
  }) async {
    await _dio.post<dynamic>('/products/$productId/reviews/$reviewId/helpful');
  }

  /// POST /reviews/upload — multipart image; returns the stored URL.
  Future<String> uploadImage(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final response = await _dio.post<dynamic>('/reviews/upload', data: formData);
    final data = response.data;
    final url = (data is Map) ? data['url'] as String? : null;
    if (url == null || url.isEmpty) {
      throw Exception('Upload failed: no URL returned');
    }
    return url;
  }
}
