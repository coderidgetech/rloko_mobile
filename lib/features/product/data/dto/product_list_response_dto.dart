import 'product_dto.dart';

/// Backend returns { "products": [], "total", "limit", "skip" }
class ProductListResponseDto {
  ProductListResponseDto({
    required this.products,
    required this.total,
    required this.limit,
    required this.skip,
  });

  factory ProductListResponseDto.fromJson(Map<String, dynamic> json) {
    final productsRaw = json['products'];
    final list = productsRaw is List
        ? (productsRaw)
            .map((e) => ProductDto.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ProductDto>[];
    return ProductListResponseDto(
      products: list,
      total: json['total'] is int ? json['total'] as int : 0,
      limit: json['limit'] is int ? json['limit'] as int : 20,
      skip: json['skip'] is int ? json['skip'] as int : 0,
    );
  }

  final List<ProductDto> products;
  final int total;
  final int limit;
  final int skip;
}
