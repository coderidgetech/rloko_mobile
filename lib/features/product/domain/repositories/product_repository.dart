import '../entities/product_entity.dart';
import '../entities/product_list_result.dart';

abstract class ProductRepository {
  Future<ProductListResult> list({
    int? limit,
    int? skip,
    String? category,
    String? gender,
    bool? onSale,
    bool? featured,
    double? minPrice,
    double? maxPrice,
    String? sort,
  });

  Future<ProductEntity> getById(String id);

  Future<List<ProductEntity>> getFeatured({int limit = 10});

  Future<List<ProductEntity>> getNewArrivals({int limit = 10});

  Future<List<ProductEntity>> getOnSale({int limit = 10});
}
