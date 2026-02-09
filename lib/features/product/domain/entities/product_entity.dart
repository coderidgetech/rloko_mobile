import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  const ProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.priceInr,
    this.originalPriceInr,
    required this.images,
    required this.category,
    required this.subcategory,
    required this.gender,
    required this.colors,
    required this.sizes,
    required this.description,
    required this.details,
    required this.material,
    required this.featured,
    required this.newArrival,
    required this.onSale,
    required this.rating,
    required this.reviews,
    this.badge,
    this.videoUrl,
    required this.stock,
    this.vendorId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final double? priceInr;
  final double? originalPriceInr;
  final List<String> images;
  final String category;
  final String subcategory;
  final String gender; // women, men, unisex
  final List<String> colors;
  final List<String> sizes;
  final String description;
  final List<String> details;
  final String material;
  final bool featured;
  final bool newArrival;
  final bool onSale;
  final double rating;
  final int reviews;
  final String? badge;
  final String? videoUrl;
  final Map<String, int> stock;
  final String? vendorId;
  final String createdAt;
  final String updatedAt;

  String? get firstImage => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [id, name, price];
}
