import '../../data/datasources/review_remote_datasource.dart';
import '../../data/dto/my_review_dto.dart';

class GetMyReviewsUseCase {
  GetMyReviewsUseCase(this._dataSource);

  final ReviewRemoteDataSource _dataSource;

  Future<({List<MyReviewDto> reviews, int total})> call({int limit = 50, int skip = 0}) =>
      _dataSource.getMyReviews(limit: limit, skip: skip);
}
