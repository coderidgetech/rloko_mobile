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
    bool? newArrival,
    bool? gift,
    double? minPrice,
    double? maxPrice,
    String? sort,
    String? search,
  });

  Future<ProductEntity> getById(String id);

  /// Color-variant siblings (same variant_group_id) for the PDP color switcher.
  Future<List<ProductEntity>> getVariants(String id);

  Future<List<ProductEntity>> getFeatured({int limit = 10});

  Future<List<ProductEntity>> getNewArrivals({int limit = 10});

  Future<List<ProductEntity>> getOnSale({int limit = 10});

  Future<List<ProductEntity>> getRecommendations(String productId, {int limit = 8});
}
