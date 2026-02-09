import 'package:equatable/equatable.dart';

class CategoryEntity extends Equatable {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
    required this.subcategories,
    required this.image,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String slug;
  final String gender; // women, men, unisex
  final List<String> subcategories;
  final String image;
  final int order;
  final String createdAt;
  final String updatedAt;

  @override
  List<Object?> get props => [id, slug];
}
