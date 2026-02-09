import '../../domain/entities/inspiration_video_entity.dart';

class InspirationVideoDto {
  InspirationVideoDto({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
    this.featured = false,
    this.uploadedByName,
    this.createdAt,
  });

  factory InspirationVideoDto.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'] ?? json['_id'];
    final id = idRaw is Map ? (idRaw['\$oid'] ?? idRaw['oid'])?.toString() : idRaw?.toString();
    final createdAtRaw = json['created_at'];
    return InspirationVideoDto(
      id: id ?? '',
      title: json['title']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      featured: json['featured'] == true,
      uploadedByName: json['uploaded_by_name']?.toString(),
      createdAt: createdAtRaw != null
          ? (createdAtRaw is String
              ? DateTime.tryParse(createdAtRaw)
              : DateTime.tryParse(createdAtRaw.toString()))
          : null,
    );
  }

  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final String category;
  final bool featured;
  final String? uploadedByName;
  final DateTime? createdAt;

  InspirationVideoEntity toEntity() {
    return InspirationVideoEntity(
      id: id,
      title: title,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      category: category,
      featured: featured,
      uploadedByName: uploadedByName,
      createdAt: createdAt ?? DateTime.now(),
    );
  }
}
