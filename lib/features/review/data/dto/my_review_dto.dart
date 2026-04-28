class MyReviewDto {
  MyReviewDto({
    required this.id,
    required this.productId,
    required this.rating,
    required this.title,
    required this.comment,
    this.productName,
    this.productImage,
    this.createdAt,
  });

  factory MyReviewDto.fromJson(Map<String, dynamic> json) {
    return MyReviewDto(
      id: json['id']?.toString() ?? '',
      productId: json['product_id']?.toString() ?? '',
      rating: (json['rating'] is int) ? json['rating'] as int : int.tryParse('${json['rating']}') ?? 0,
      title: json['title']?.toString() ?? '',
      comment: json['comment']?.toString() ?? '',
      productName: json['product_name']?.toString(),
      productImage: json['product_image']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  final String id;
  final String productId;
  final int rating;
  final String title;
  final String comment;
  final String? productName;
  final String? productImage;
  final String? createdAt;
}
