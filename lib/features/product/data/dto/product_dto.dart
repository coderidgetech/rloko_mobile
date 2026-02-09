import '../../domain/entities/product_entity.dart';

class ProductDto {
  ProductDto({
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

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    final imagesRaw = json['images'];
    final images = imagesRaw is List
        ? (imagesRaw).map((e) => e.toString()).toList()
        : <String>[];
    final colorsRaw = json['colors'];
    final colors = colorsRaw is List
        ? (colorsRaw).map((e) => e.toString()).toList()
        : <String>[];
    final sizesRaw = json['sizes'];
    final sizes = sizesRaw is List
        ? (sizesRaw).map((e) => e.toString()).toList()
        : <String>[];
    final detailsRaw = json['details'];
    final details = detailsRaw is List
        ? (detailsRaw).map((e) => e.toString()).toList()
        : <String>[];
    final stockRaw = json['stock'];
    Map<String, int> stock = {};
    if (stockRaw is Map) {
      for (final e in stockRaw.entries) {
        stock[e.key.toString()] = (e.value is int)
            ? e.value as int
            : int.tryParse(e.value.toString()) ?? 0;
      }
    }
    return ProductDto(
      id: _string(json['id']),
      name: json['name'] as String? ?? '',
      price: _double(json['price']),
      originalPrice: _doubleOrNull(json['original_price']),
      priceInr: _doubleOrNull(json['price_inr']),
      originalPriceInr: _doubleOrNull(json['original_price_inr']),
      images: images,
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      gender: json['gender'] as String? ?? 'unisex',
      colors: colors,
      sizes: sizes,
      description: json['description'] as String? ?? '',
      details: details,
      material: json['material'] as String? ?? '',
      featured: json['featured'] as bool? ?? false,
      newArrival: json['new_arrival'] as bool? ?? false,
      onSale: json['on_sale'] as bool? ?? false,
      rating: _double(json['rating']),
      reviews: json['reviews'] is int ? json['reviews'] as int : 0,
      badge: json['badge'] as String?,
      videoUrl: json['video_url'] as String?,
      stock: stock,
      vendorId: json['vendor_id']?.toString(),
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
  final double price;
  final double? originalPrice;
  final double? priceInr;
  final double? originalPriceInr;
  final List<String> images;
  final String category;
  final String subcategory;
  final String gender;
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

  static String _string(dynamic v) => v?.toString() ?? '';
  static double _double(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
  static double? _doubleOrNull(dynamic v) =>
      (v is num) ? v.toDouble() : double.tryParse(v?.toString() ?? '');

  ProductEntity toEntity() => ProductEntity(
        id: id,
        name: name,
        price: price,
        originalPrice: originalPrice,
        priceInr: priceInr,
        originalPriceInr: originalPriceInr,
        images: images,
        category: category,
        subcategory: subcategory,
        gender: gender,
        colors: colors,
        sizes: sizes,
        description: description,
        details: details,
        material: material,
        featured: featured,
        newArrival: newArrival,
        onSale: onSale,
        rating: rating,
        reviews: reviews,
        badge: badge,
        videoUrl: videoUrl,
        stock: stock,
        vendorId: vendorId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
