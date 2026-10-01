import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/region/app_region.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../bloc/product_list_bloc.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../../domain/entities/product_entity.dart';

/// Subcategory pills per gender (matches React MobileCategoryPage).
const _womenSubCategories = ['All', 'Dresses', 'Tops', 'Bottoms', 'Outerwear', 'Shoes', 'Bags', 'Jewelry'];
const _menSubCategories = ['All', 'Shirts', 'Pants', 'Outerwear', 'Shoes', 'Accessories'];

class CategoryProductsPage extends StatefulWidget {
  const CategoryProductsPage({
    super.key,
    required this.gender,
    required this.slug,
    this.isGiftMode = false,
  });

  final String gender;
  final String slug;
  final bool isGiftMode;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String _sortBy = 'featured';
  String _selectedSubCategory = 'all';
  bool _showFeaturedOnly = false;
  CategoryFilterState _filterState = const CategoryFilterState();
  // Products the filter facets are derived from (subcategory-scoped, pre-filter).
  List<ProductEntity> _facetSource = const [];

  bool get _isIndia => CurrencyScope.of(context).region == AppRegion.india;

  /// Header title — the gift label, the subcategory, or the gender, capitalized.
  String get _pageTitle {
    if (widget.isGiftMode) {
      return widget.gender == 'women'
          ? 'Gifts for Her'
          : widget.gender == 'men'
              ? 'Gifts for Him'
              : 'Gifts';
    }
    final raw = (widget.slug.isNotEmpty && widget.slug != widget.gender)
        ? widget.slug
        : widget.gender;
    if (raw.isEmpty) return 'Products';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  /// Compact context trail shown alongside the Filter/Sort controls — mirrors
  /// the web CategoryPage's "Home / Gender / Category" breadcrumb using the
  /// same gender/slug/gift inputs as [_pageTitle], just styled as a muted,
  /// single-line label instead of a chain of tappable crumbs (there's no
  /// in-page breadcrumb pattern on mobile; the back button covers "Home").
  String get _breadcrumbLabel {
    if (widget.isGiftMode) return _pageTitle;
    final gender = widget.gender.isEmpty
        ? 'All'
        : widget.gender[0].toUpperCase() + widget.gender.substring(1);
    final hasSubcategory = widget.slug.isNotEmpty && widget.slug != widget.gender;
    if (!hasSubcategory) return gender;
    final category = widget.slug[0].toUpperCase() + widget.slug.substring(1);
    return '$gender  ›  $category';
  }

  int get _activeFilterCount => _filterState.activeCount;

  bool get _sortActive => _sortBy != 'featured';

  String get _sortLabel {
    switch (_sortBy) {
      case 'newest':
        return 'Newest';
      case 'price-low':
        return 'Price ↑';
      case 'price-high':
        return 'Price ↓';
      default:
        return 'Sort';
    }
  }

  List<ProductEntity> _filterAndSort(List<ProductEntity> products) {
    var list = products;
    if (_selectedSubCategory != 'all') {
      list = list.where((p) =>
          p.category.toLowerCase() == _selectedSubCategory.toLowerCase()).toList();
    }
    if (_showFeaturedOnly) {
      list = list.where((p) => p.featured).toList();
    }
    list = applyCategoryFilters(list, _filterState, priceOf: priceSelector(india: _isIndia));
    list = List.from(list);
    if (_sortBy == 'price-low') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price-high') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'newest') {
      list.sort((a, b) => (b.newArrival ? 1 : 0).compareTo(a.newArrival ? 1 : 0));
    } else if (_sortBy == 'featured') {
      list.sort((a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    }
    return list;
  }

  Future<void> _showSortSheet() async {
    final result = await showSortBottomSheet(
      context,
      options: const [
        SortOption(value: 'featured', label: 'Featured'),
        SortOption(value: 'newest', label: 'Newest'),
        SortOption(value: 'price-low', label: 'Price: Low to High'),
        SortOption(value: 'price-high', label: 'Price: High to Low'),
      ],
      selectedValue: _sortBy,
    );
    if (result != null && mounted) setState(() => _sortBy = result);
  }

  Future<void> _showFilterSheet() async {
    final scope = CurrencyScope.of(context);
    final facets = computeFacets(
      _facetSource,
      priceSelector(india: scope.region == AppRegion.india),
    );
    final result = await showFilterBottomSheet(
      context,
      initial: _filterState,
      facets: facets,
      formatPrice: scope.formatAmount,
    );
    if (result != null && mounted) setState(() => _filterState = result);
  }

  /// Maps the URL slug to the API `category` query param.
  ///
  /// Rules:
  /// - Empty slug → null (load all for this gender)
  /// - Slug equals gender (e.g. "women" under gender "women") → null (top-level
  ///   gender category; products use specific values like "Dresses", "Tops")
  /// - "clothing" / "accessories" → null (broad bucket slugs that don't match
  ///   any product.category value directly)
  /// - Anything else → pass through so the backend regex-matches it
  String? _apiCategoryParam() {
    if (widget.slug.isEmpty) return null;
    if (widget.slug == widget.gender) return null;
    if (widget.slug == 'clothing' || widget.slug == 'accessories') return null;
    return widget.slug;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final category = _apiCategoryParam();
    context.read<ProductListBloc>().add(
          ProductListLoadRequested(
            gender: widget.gender,
            category: category,
            limit: 200,
            gift: widget.isGiftMode ? true : null,
          ),
        );
  }

  @override
  void didUpdateWidget(CategoryProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender || oldWidget.slug != widget.slug) {
      final category = _apiCategoryParam();
      context.read<ProductListBloc>().add(
            ProductListLoadRequested(
              gender: widget.gender,
              category: category,
              limit: 200,
              gift: widget.isGiftMode ? true : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Subcategory pills: only when gender && !category (React logic)
    final showSubPills = widget.gender.isNotEmpty && widget.slug.isEmpty;
    final subCategories = widget.gender == 'women'
        ? _womenSubCategories
        : widget.gender == 'men'
            ? _menSubCategories
            : ['All'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppHeader(showBackButton: true, title: _pageTitle),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          // Show loading when: explicitly loading, or still initial/home state (load was just dispatched)
          if (state is ProductListLoading ||
              state is ProductListHomeLoading ||
              state is ProductListInitial ||
              state is ProductListHomeLoaded) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ProductGridSkeleton(itemCount: 6),
            );
          }
          if (state is ProductListError) {
            return ErrorStateView(
              message: state.message,
              onRetry: _load,
            );
          }
          if (state is ProductListLoaded) {
            // Facets reflect the current category (subcategory-scoped), independent
            // of which filters are currently applied.
            _facetSource = _selectedSubCategory == 'all'
                ? state.products
                : state.products
                    .where((p) => p.category.toLowerCase() == _selectedSubCategory.toLowerCase())
                    .toList();
            final products = _filterAndSort(state.products);
            // The AppHeader carries the title too (shared app-wide chrome with
            // search/wishlist/cart); the refine bar's own title/count line is
            // the demoted secondary line from the web-parity consolidation
            // below, kept so the page doesn't only rely on the app bar.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFixedFilterBar(products.length, showSubPills, subCategories),
                Expanded(
                  child: products.isEmpty
                      ? _buildCategoryEmptyState()
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            // Match product_list_page: 3/4 image + info block.
                            childAspectRatio: 0.56,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) => ProductGridTile(product: products[index]),
                        ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Empty state matching React EmptyState (type="category"): icon, title, description, Clear Filters button.
  Widget _buildCategoryEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon: 80x80 rounded circle, bg-foreground/5, icon 32px foreground/40
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 32,
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor(context),
                  ) ??
                  TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AppTheme.foregroundColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                'Try adjusting your filters or browse other categories',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => setState(() {
                _filterState = const CategoryFilterState();
                _selectedSubCategory = 'all';
              }),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                foregroundColor: AppTheme.primaryForegroundColor(context),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              ),
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  /// Refine bar. Consolidated (matches web's CategoryPage): the breadcrumb-style
  /// context trail shares one row with the Filter (active-count badge) and Sort
  /// (current selection) controls. The full page title + item count moved to
  /// their own secondary line directly below — demoted, not deleted. Sibling
  /// subcategory chips (a mobile-only affordance, unrelated to this change)
  /// stay in place beneath that.
  Widget _buildFixedFilterBar(
    int count,
    bool showSubPills,
    List<String> subCategories,
  ) {
    final fg = AppTheme.foregroundColor(context);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: fg.withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Consolidated: breadcrumb-style context + Featured + Filter + Sort —
          // one scrollable row, so on a narrow screen nothing gets silently
          // squeezed/hidden with no way to reach it (the whole row scrolls
          // instead of the breadcrumb losing a fight for space against the
          // pills).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _breadcrumbLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                      color: fg.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _refinePill(
                    icon: Icons.tune_rounded,
                    label: _activeFilterCount > 0 ? 'Filter · $_activeFilterCount' : 'Filter',
                    active: _activeFilterCount > 0,
                    onTap: _showFilterSheet,
                  ),
                  const SizedBox(width: 8),
                  _refinePill(
                    icon: Icons.swap_vert_rounded,
                    label: _sortLabel,
                    active: _sortActive,
                    onTap: _showSortSheet,
                  ),
                  const SizedBox(width: 8),
                  _refinePill(
                    icon: Icons.star_rounded,
                    label: 'Featured Only',
                    active: _showFeaturedOnly,
                    onTap: () => setState(() => _showFeaturedOnly = !_showFeaturedOnly),
                  ),
                ],
              ),
            ),
          ),
          // Title + item count — secondary line, directly below the consolidated bar.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    _pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          // Sibling subcategory chips (All / Dresses / Tops ...).
          if (showSubPills)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: fg.withValues(alpha: 0.1)))),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: subCategories.map((s) {
                    final slug = s.toLowerCase();
                    final selected = _selectedSubCategory == slug;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedSubCategory = slug),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.primaryColor(context) : AppTheme.backgroundColor(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: selected ? AppTheme.primaryColor(context) : fg.withValues(alpha: 0.2),
                            ),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : fg.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _refinePill({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final fg = AppTheme.foregroundColor(context);
    final accent = AppTheme.primaryColor(context);
    final color = active ? accent : fg.withValues(alpha: 0.7);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? accent.withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(color: active ? accent : fg.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
