import '../entities/inspiration_video_entity.dart';
import '../repositories/video_repository.dart';

class GetInspirationVideosUseCase {
  GetInspirationVideosUseCase(this._repository);

  final VideoRepository _repository;

  Future<List<InspirationVideoEntity>> call({int limit = 20}) async {
    return _repository.list(limit: limit);
  }
}
