import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../config/domain/entities/site_config.dart';
import '../../../config/presentation/bloc/config_bloc.dart';
import '../../../config/utils/config_category_utils.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/category_list_bloc.dart';

/// One row in the category grid: from API, config fallback, or a fixed nav link (e.g. new, sale, all).
class _CategoryItem {
  const _CategoryItem({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.link,
    this.badge,
    this.subcategories,
    this.icon = Icons.checkroom,
  });

  final String id;
  final String name;
  final String image;
  final String description;
  final String link;
  final String? badge;
  final List<_SubcategoryItem>? subcategories;
  /// Shown on the card when [image] is empty or fails to load.
  final IconData icon;
}

class _SubcategoryItem {
  const _SubcategoryItem({
    required this.name,
    required this.link,
  });

  final String name;
  final String link;
}

String _slugifySubName(String s) {
  return s
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
}

List<_CategoryItem> _categoriesListFromState({
  required CategoryListState? categoryState,
  required SiteConfig config,
}) {
  var list = <CategoryEntity>[];
  if (categoryState is CategoryListLoaded) {
    list = List<CategoryEntity>.from(categoryState.categories)..sort((a, b) => a.order.compareTo(b.order));
  }
  if (list.isEmpty) {
    list = categoriesFromConfig(config.categories)..sort((a, b) => a.order.compareTo(b.order));
  }
  final out = <_CategoryItem>[
    const _CategoryItem(
      id: 'all-products',
      name: 'All Products',
      // Distinct from the catalog category images (Women uses 1483985988355).
      image: 'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800&q=80',
      description: 'Browse the full catalog',
      badge: 'Shop All',
      link: '/all-products',
      icon: Icons.grid_view_rounded,
    ),
  ];
  for (final c in list) {
    final subItems = c.subcategories
        .map(
          (s) => _SubcategoryItem(
            name: s,
            link: '/category/${c.gender}/${_slugifySubName(s)}',
          ),
        )
        .toList();
    out.add(
      _CategoryItem(
        id: c.id,
        name: c.name,
        image: c.image,
        description: subItems.isNotEmpty ? 'Collections in this category' : 'Shop this collection',
        link: '/category/${c.gender}/${c.slug}',
        subcategories: subItems.isEmpty ? null : subItems,
      ),
    );
  }
  out.add(
    const _CategoryItem(
      id: 'new',
      name: 'New Arrivals',
      image: 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=800&q=80',
      description: 'Just added to the store',
      badge: 'New',
      link: '/new-arrivals',
      icon: Icons.auto_awesome,
    ),
  );
  out.add(
    const _CategoryItem(
      id: 'sale',
      name: 'Sale',
      image: 'https://images.unsplash.com/photo-1445205170230-053b83016050?w=800&q=80',
      description: 'Current offers',
      badge: 'Sale',
      link: '/sale',
      icon: Icons.local_offer,
    ),
  );
  return out;
}

/// Categories page: grid of collections from the API (or config fallback) plus all / new / sale.
/// 2-col grid, aspect 3/4 cards, gradient overlay, badge, tap to expand bottom sheet for subcategories.
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  /// Ref: expandedCategory state - tap category with subcategories toggles this; overlay shows when set.
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    context.read<CategoryListBloc>().add(const CategoryListLoadRequested());
  }

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
    return BlocBuilder<ConfigBloc, ConfigState>(
      buildWhen: (a, b) => b is ConfigLoaded || a is! ConfigLoaded,
      builder: (context, configState) {
        final config = configState is ConfigLoaded ? configState.config : SiteConfig.defaultConfig;
        return BlocBuilder<CategoryListBloc, CategoryListState>(
          builder: (context, categoryState) {
            final display = _categoriesListFromState(
              categoryState: categoryState,
              config: config,
            );
            _CategoryItem? expandedCategory;
            if (_expandedCategoryId != null) {
              for (final c in display) {
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
                              itemCount: display.length,
                              itemBuilder: (context, index) {
                                final category = display[index];
                                return _CategoryGridCard(
                                  category: category,
                                  totalLabel: '',
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
    );
          },
        );
      },
    );
  }
}

/// Single category card: aspect 3/4, rounded-lg, border, image, gradient, badge, name, description, "X types" + chevron.
/// Ref: tap toggles expand (if has subcategories); chevron rotates 90° when expanded.
class _CategoryGridCard extends StatelessWidget {
  const _CategoryGridCard({
    required this.category,
    required this.totalLabel,
    required this.isExpanded,
    required this.onTap,
  });

  final _CategoryItem category;
  final String totalLabel;
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
              if (safeImageUrl(category.image).isEmpty)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.mutedColor(context),
                        AppTheme.primaryColor(context).withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      size: 48,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.25),
                    ),
                  ),
                )
              else
                CachedNetworkImage(
                  imageUrl: safeImageUrl(category.image),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.mutedColor(context)),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.mutedColor(context),
                          AppTheme.primaryColor(context).withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        category.icon,
                        size: 48,
                        color: AppTheme.foregroundColor(context).withValues(alpha: 0.25),
                      ),
                    ),
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
                    if (totalLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        totalLabel,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
                  ],
                ),
              ),
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
