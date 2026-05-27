import 'package:equatable/equatable.dart';

class MyReviewEntity extends Equatable {
  const MyReviewEntity({
    required this.id,
    required this.productId,
    required this.rating,
    required this.title,
    required this.comment,
    this.productName,
    this.productImage,
    this.createdAt,
  });

  final String id;
  final String productId;
  final int rating;
  final String title;
  final String comment;
  final String? productName;
  final String? productImage;
  final String? createdAt;

  @override
  List<Object?> get props => [id, productId];
}

class ProductReviewEntity extends Equatable {
  const ProductReviewEntity({
    required this.id,
    required this.userName,
    required this.rating,
    required this.title,
    required this.comment,
    this.createdAt,
  });

  final String id;
  final String userName;
  final int rating;
  final String title;
  final String comment;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id];
}
