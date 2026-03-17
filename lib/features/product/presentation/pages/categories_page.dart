import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../../../../core/widgets/safe_network_image.dart';

/// Static category item matching React MobileCategoriesPage CATEGORIES.
class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.itemCount,
    required this.link,
    this.badge,
    this.subcategories,
  });

  final String id;
  final String name;
  final String image;
  final String description;
  final String itemCount;
  final String link;
  final String? badge;
  final List<_SubcategoryItem>? subcategories;
}

class _SubcategoryItem {
  const _SubcategoryItem({
    required this.name,
    required this.count,
    required this.link,
    this.badge,
  });

  final String name;
  final String count;
  final String link;
  final String? badge;
}

/// Static list matching React MobileCategoriesPage exactly.
const List<_CategoryItem> _kCategories = [
  _CategoryItem(
    id: 'all-products',
    name: 'All Products',
    image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=600&q=80',
    description: 'Browse our complete collection',
    itemCount: '5,000+ Items',
    badge: 'Shop All',
    link: '/all-products',
  ),
  _CategoryItem(
    id: 'women',
    name: 'Women',
    image: 'https://images.unsplash.com/photo-1483985988355-763728e1935b?w=600&q=80',
    description: "Explore the latest trends in women's fashion",
    itemCount: '2,450+ Items',
    link: '/category/women',
    subcategories: [
      _SubcategoryItem(name: 'Dresses', count: '450+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Tops & Blouses', count: '380+', link: '/category/women/tops'),
      _SubcategoryItem(name: 'Bottoms', count: '320+', link: '/category/women/bottoms'),
      _SubcategoryItem(name: 'Outerwear & Jackets', count: '280+', link: '/category/women/outerwear'),
      _SubcategoryItem(name: 'Activewear', count: '240+', link: '/category/women/activewear'),
      _SubcategoryItem(name: 'Lingerie & Sleepwear', count: '190+', link: '/category/women/lingerie'),
      _SubcategoryItem(name: 'Shoes', count: '520+', link: '/category/women/shoes'),
      _SubcategoryItem(name: 'Bags & Handbags', count: '340+', link: '/category/women/bags'),
      _SubcategoryItem(name: 'Jewelry', count: '230+', link: '/category/women/jewelry'),
    ],
  ),
  _CategoryItem(
    id: 'men',
    name: 'Men',
    image: 'https://images.unsplash.com/photo-1617127365659-c47fa864d8bc?w=600&q=80',
    description: "Discover sophisticated men's styles",
    itemCount: '1,850+ Items',
    link: '/category/men',
    subcategories: [
      _SubcategoryItem(name: 'Shirts & T-Shirts', count: '420+', link: '/category/men/shirts'),
      _SubcategoryItem(name: 'Pants & Jeans', count: '350+', link: '/category/men/pants'),
      _SubcategoryItem(name: 'Suits & Blazers', count: '180+', link: '/category/men/suits'),
      _SubcategoryItem(name: 'Outerwear', count: '220+', link: '/category/men/outerwear'),
      _SubcategoryItem(name: 'Activewear', count: '190+', link: '/category/men/activewear'),
      _SubcategoryItem(name: 'Shoes', count: '380+', link: '/category/men/shoes'),
      _SubcategoryItem(name: 'Accessories', count: '110+', link: '/category/men/accessories'),
    ],
  ),
  _CategoryItem(
    id: 'new',
    name: 'New Arrivals',
    image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=600&q=80',
    description: 'Fresh styles just landed',
    itemCount: '580+ Items',
    badge: 'New',
    link: '/new-arrivals',
    subcategories: [
      _SubcategoryItem(name: 'This Week', count: '120+', link: '/new-arrivals', badge: 'Hot'),
      _SubcategoryItem(name: 'This Month', count: '280+', link: '/new-arrivals'),
      _SubcategoryItem(name: "Women's New", count: '340+', link: '/new-arrivals'),
      _SubcategoryItem(name: "Men's New", count: '240+', link: '/new-arrivals'),
      _SubcategoryItem(name: 'Coming Soon', count: '95+', link: '/new-arrivals', badge: 'Soon'),
    ],
  ),
  _CategoryItem(
    id: 'sale',
    name: 'Sale',
    image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=600&q=80',
    description: 'Amazing deals up to 70% off',
    itemCount: '920+ Items',
    badge: 'Up to 70% Off',
    link: '/sale',
    subcategories: [
      _SubcategoryItem(name: 'Up to 30% Off', count: '280+', link: '/sale', badge: '30%'),
      _SubcategoryItem(name: 'Up to 50% Off', count: '340+', link: '/sale', badge: '50%'),
      _SubcategoryItem(name: 'Up to 70% Off', count: '180+', link: '/sale', badge: '70%'),
      _SubcategoryItem(name: 'Final Sale', count: '120+', link: '/sale', badge: 'Final'),
      _SubcategoryItem(name: "Women's Sale", count: '520+', link: '/sale'),
      _SubcategoryItem(name: "Men's Sale", count: '400+', link: '/sale'),
    ],
  ),
  _CategoryItem(
    id: 'dresses',
    name: 'Dresses',
    image: 'https://images.unsplash.com/photo-1595777457583-95e059d581b8?w=600&q=80',
    description: 'Perfect dresses for every occasion',
    itemCount: '680+ Items',
    link: '/category/women/dresses',
    subcategories: [
      _SubcategoryItem(name: 'Casual Dresses', count: '180+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Evening Dresses', count: '140+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Cocktail Dresses', count: '120+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Maxi Dresses', count: '95+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Mini Dresses', count: '85+', link: '/category/women/dresses'),
      _SubcategoryItem(name: 'Midi Dresses', count: '60+', link: '/category/women/dresses'),
    ],
  ),
  _CategoryItem(
    id: 'shoes',
    name: 'Shoes',
    image: 'https://images.unsplash.com/photo-1543163521-1bf539c55dd2?w=600&q=80',
    description: 'Step into style and comfort',
    itemCount: '920+ Items',
    link: '/category/women/shoes',
    subcategories: [
      _SubcategoryItem(name: 'Sneakers & Athletic', count: '280+', link: '/category/women/shoes'),
      _SubcategoryItem(name: 'Heels & Pumps', count: '190+', link: '/category/women/shoes'),
      _SubcategoryItem(name: 'Boots & Booties', count: '220+', link: '/category/women/shoes'),
      _SubcategoryItem(name: 'Sandals & Slides', count: '140+', link: '/category/women/shoes'),
      _SubcategoryItem(name: 'Flats & Loafers', count: '90+', link: '/category/women/shoes'),
    ],
  ),
  _CategoryItem(
    id: 'bags',
    name: 'Bags & Accessories',
    image: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600&q=80',
    description: 'Complete your look with perfect accessories',
    itemCount: '540+ Items',
    link: '/category/women/clothing',
    subcategories: [
      _SubcategoryItem(name: 'Handbags & Totes', count: '180+', link: '/category/women/bags'),
      _SubcategoryItem(name: 'Backpacks', count: '95+', link: '/category/women/bags'),
      _SubcategoryItem(name: 'Clutches & Evening Bags', count: '80+', link: '/category/women/bags'),
      _SubcategoryItem(name: 'Wallets & Cardholders', count: '120+', link: '/category/women/bags'),
      _SubcategoryItem(name: 'Belts', count: '65+', link: '/category/women/bags'),
    ],
  ),
  _CategoryItem(
    id: 'jewelry',
    name: 'Jewelry',
    image: 'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?w=600&q=80',
    description: 'Elegant pieces to elevate any outfit',
    itemCount: '450+ Items',
    link: '/category/women/jewelry',
    subcategories: [
      _SubcategoryItem(name: 'Necklaces & Pendants', count: '120+', link: '/category/women/jewelry'),
      _SubcategoryItem(name: 'Earrings', count: '140+', link: '/category/women/jewelry'),
      _SubcategoryItem(name: 'Bracelets & Bangles', count: '90+', link: '/category/women/jewelry'),
      _SubcategoryItem(name: 'Rings', count: '75+', link: '/category/women/jewelry'),
      _SubcategoryItem(name: 'Watches', count: '25+', link: '/category/women/jewelry'),
    ],
  ),
  _CategoryItem(
    id: 'cosmetics',
    name: 'Cosmetics & Beauty',
    image: 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=600&q=80',
    description: 'Premium beauty and skincare essentials',
    itemCount: '620+ Items',
    link: '/category/women/clothing',
    subcategories: [
      _SubcategoryItem(name: 'Makeup', count: '220+', link: '/category/women/clothing'),
      _SubcategoryItem(name: 'Skincare', count: '180+', link: '/category/women/clothing'),
      _SubcategoryItem(name: 'Fragrance', count: '95+', link: '/category/women/clothing'),
      _SubcategoryItem(name: 'Haircare', count: '85+', link: '/category/women/clothing'),
      _SubcategoryItem(name: 'Beauty Tools', count: '40+', link: '/category/women/clothing'),
    ],
  ),
];

/// Categories page matching React MobileCategoriesPage exactly:
/// 2-col grid, aspect 3/4 cards, gradient overlay, badge, tap to expand bottom sheet for subcategories.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  /// Ref: expandedCategory state - tap category with subcategories toggles this; overlay shows when set.
  String? _expandedCategoryId;

  void _onCategoryTap(_CategoryItem category) {
    if (category.subcategories != null && category.subcategories!.isNotEmpty) {
      setState(() {
        _expandedCategoryId = _expandedCategoryId == category.id ? null : category.id;
      });
    } else {
      context.push(category.link);
    }
  }

  @override
  Widget build(BuildContext context) {
    _CategoryItem? expandedCategory;
    if (_expandedCategoryId != null) {
      for (final c in _kCategories) {
        if (c.id == _expandedCategoryId) {
          expandedCategory = c;
          break;
        }
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: false),
      body: Stack(
        children: [
          // Main content - Ref: flex-1 flex flex-col overflow-hidden
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page header - React: px-4 py-2, text-lg font-semibold, text-[9px] text-foreground/60
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foregroundColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to explore collections',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: [
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 3 / 4,
                      ),
                      itemCount: _kCategories.length,
                      itemBuilder: (context, index) {
                        final category = _kCategories[index];
                        return _CategoryGridCard(
                          category: category,
                          isExpanded: _expandedCategoryId == category.id,
                          onTap: () => _onCategoryTap(category),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Ref: Expandable Subcategories Overlay - fixed inset-0 bg-black/60 z-50 flex items-end
          if (expandedCategory != null && expandedCategory.subcategories != null) ...[
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _expandedCategoryId = null),
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.black.withValues(alpha: 0.6)),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _SubcategoriesOverlay(
              category: expandedCategory,
              onSubcategoryTap: (link) {
                setState(() => _expandedCategoryId = null);
                context.push(link);
              },
              onDismiss: () => setState(() => _expandedCategoryId = null),
            ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }
}

/// Single category card: aspect 3/4, rounded-lg, border, image, gradient, badge, name, description, "X types" + chevron.
/// Ref: tap toggles expand (if has subcategories); chevron rotates 90° when expanded.
class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.isExpanded,
    required this.onTap,
  });

  final _CategoryItem category;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubs = category.subcategories != null && category.subcategories!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              CachedNetworkImage(
                imageUrl: safeImageUrl(category.image),
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                errorWidget: (_, __, ___) => Container(
                  color: AppTheme.mutedColor(context),
                  child: const Icon(Icons.image, size: 40),
                ),
              ),
              // Gradient - React: from-black/90 via-black/40 to-transparent
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.4),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              // Badge - React: top-1 right-1, bg-primary/95, Sparkles, text-[10px] font-bold uppercase
              if (category.badge != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor(context).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          category.badge!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Bottom content - React: p-2.5, name text-sm font-bold, description text-[11px] white/75 line-clamp-1
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.description,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasSubs) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${category.subcategories!.length} types',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Transform.rotate(
                            angle: isExpanded ? 0.5 * 3.14159 : 0,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ref: Expandable Subcategories Overlay - fixed inset-0, panel slides up from bottom (motion initial y: 100%, animate y: 0).
/// Tap panel does not close; tap backdrop closes.
class _SubcategoriesOverlay extends StatelessWidget {
  const _SubcategoriesOverlay({
    required this.category,
    required this.onSubcategoryTap,
    required this.onDismiss,
  });

  final _CategoryItem category;
  final void Function(String link) onSubcategoryTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final subs = category.subcategories!;
    final screenHeight = MediaQuery.of(context).size.height;
    return TweenAnimationBuilder<double>(
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, value * screenHeight),
            child: child,
          );
        },
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: BoxConstraints(maxHeight: screenHeight * 0.7),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar - Ref: w-12 h-1 bg-foreground/20 rounded-full, pt-3 pb-2
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header - Ref: px-4 pb-3 border-b border-border/20
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.foregroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${subs.length} Collections',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
                // Subcategories - Ref: p-4 overflow-y-auto max-h-[calc(70vh-120px)], grid grid-cols-2 gap-2
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.8,
                      children: subs.map((sub) => _SubcategoryGridTile(
                        sub: sub,
                        onTap: () => onSubcategoryTap(sub.link),
                      )).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }
}

/// Single subcategory row in sheet - Ref: flex items-center justify-between p-3 bg-background rounded-lg border border-border/30 - React: p-3 bg-background rounded-lg border, name + count, optional badge, ChevronRight
class _SubcategoryGridTile extends StatelessWidget {
  const _SubcategoryGridTile({required this.sub, required this.onTap});

  final _SubcategoryItem sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      sub.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foregroundColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub.count,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (sub.badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    sub.badge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 12,
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
