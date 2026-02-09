import '../entities/inspiration_video_entity.dart';

abstract class VideoRepository {
  Future<List<InspirationVideoEntity>> list({int? limit, int? skip, String? category, bool? featured});
  Future<InspirationVideoEntity> getById(String id);
  Future<List<InspirationVideoEntity>> getFeatured({int limit = 10});
}
