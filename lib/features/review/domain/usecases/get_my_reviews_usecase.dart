import '../entities/review_entity.dart';
import '../repositories/review_repository.dart';

class GetMyReviewsUseCase {
  GetMyReviewsUseCase(this._repository);

  final ReviewRepository _repository;

  Future<({List<MyReviewEntity> reviews, int total})> call({int limit = 50, int skip = 0}) =>
      _repository.getMyReviews(limit: limit, skip: skip);
}
