/// Public product review (GET /products/:id/reviews).
class ProductReviewDto {
  const ProductReviewDto({
    required this.id,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    required this.createdAt,
  });

  factory ProductReviewDto.fromJson(Map<String, dynamic> json) {
    return ProductReviewDto(
      id: json['id']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Customer',
      rating: (json['rating'] is int) ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 0,
      title: json['title']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      createdAt: _parseTime(json['created_at']),
    );
  }

  final String id;
  final String userName;
  final int rating;
  final String title;
  final String comment;
  final DateTime? createdAt;

  static DateTime? _parseTime(Object? v) {
    if (v == null) return null;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
