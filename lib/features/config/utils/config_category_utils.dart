import '../../product/domain/entities/category_entity.dart';
import '../domain/entities/site_config.dart';

/// When the API has no [CategoryEntity.image], UI uses a local muted placeholder (no stock photos).
String fallbackImageForCategory(String _, String __) {
  return '';
}

/// Converts config categories to CategoryEntity list for fallback display when API returns empty.
List<CategoryEntity> categoriesFromConfig(CategoriesConfig config) {
  final now = DateTime.now().toIso8601String();
  return [
    CategoryEntity(
      id: 'config-women-clothing',
      name: "Women's Clothing",
      slug: 'clothing',
      gender: 'women',
      subcategories: config.women.clothing,
      image: '',
      order: 0,
      createdAt: now,
      updatedAt: now,
    ),
    CategoryEntity(
      id: 'config-women-accessories',
      name: "Women's Accessories",
      slug: 'accessories',
      gender: 'women',
      subcategories: config.women.accessories,
      image: '',
      order: 1,
      createdAt: now,
      updatedAt: now,
    ),
    CategoryEntity(
      id: 'config-men-clothing',
      name: "Men's Clothing",
      slug: 'clothing',
      gender: 'men',
      subcategories: config.men.clothing,
      image: '',
      order: 2,
      createdAt: now,
      updatedAt: now,
    ),
    CategoryEntity(
      id: 'config-men-accessories',
      name: "Men's Accessories",
      slug: 'accessories',
      gender: 'men',
      subcategories: config.men.accessories,
      image: '',
      order: 3,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
