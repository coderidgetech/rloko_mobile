import '../../product/domain/entities/category_entity.dart';
import '../domain/entities/site_config.dart';

/// Distinct placeholder images per category type (matching web MobileCategoriesPage).
const _fallbackImageWomenClothing =
    'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80';
const _fallbackImageWomenAccessories =
    'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&q=80';
const _fallbackImageMenClothing =
    'https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=600&q=80';
const _fallbackImageMenAccessories =
    'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&q=80';

/// Returns a distinct fallback image based on category gender and slug.
/// Use when category.image is empty (API or config) so each category type shows a different image.
String fallbackImageForCategory(String gender, String slug) {
  if (gender == 'women' && slug == 'clothing') return _fallbackImageWomenClothing;
  if (gender == 'women' && slug == 'accessories') return _fallbackImageWomenAccessories;
  if (gender == 'men' && slug == 'clothing') return _fallbackImageMenClothing;
  if (gender == 'men' && slug == 'accessories') return _fallbackImageMenAccessories;
  // For API categories with other slugs, pick by hash for variety
  const images = [
    _fallbackImageWomenClothing,
    _fallbackImageWomenAccessories,
    _fallbackImageMenClothing,
    _fallbackImageMenAccessories,
  ];
  return images[(gender.hashCode + slug.hashCode).abs() % images.length];
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
      image: _fallbackImageWomenClothing,
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
      image: _fallbackImageWomenAccessories,
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
      image: _fallbackImageMenClothing,
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
      image: _fallbackImageMenAccessories,
      order: 3,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
