import '../../domain/entities/category_entity.dart';

class CategoryDto {
  CategoryDto({
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

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    final subRaw = json['subcategories'];
    final subcategories = subRaw is List
        ? (subRaw).map((e) => e.toString()).toList()
        : <String>[];
    return CategoryDto(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      gender: json['gender'] as String? ?? 'unisex',
      subcategories: subcategories,
      image: json['image'] as String? ?? '',
      order: json['order'] is int ? json['order'] as int : 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())?.toIso8601String() ?? ''
          : '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())?.toIso8601String() ?? ''
          : '',
    );
  }

  final String id;
  final String name;
  final String slug;
  final String gender;
  final List<String> subcategories;
  final String image;
  final int order;
  final String createdAt;
  final String updatedAt;

  CategoryEntity toEntity() => CategoryEntity(
        id: id,
        name: name,
        slug: slug,
        gender: gender,
        subcategories: subcategories,
        image: image,
        order: order,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
