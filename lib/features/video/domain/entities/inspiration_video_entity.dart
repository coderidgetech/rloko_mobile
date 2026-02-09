import 'package:equatable/equatable.dart';

class InspirationVideoEntity extends Equatable {
  const InspirationVideoEntity({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.category,
    this.featured = false,
    this.uploadedByName,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final String category;
  final bool featured;
  final String? uploadedByName;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, title, videoUrl, thumbnailUrl, category, featured, uploadedByName, createdAt];
}
