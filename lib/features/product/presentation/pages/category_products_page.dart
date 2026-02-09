import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/bottom_nav.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/quick_actions.dart';
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
  });

  final String gender;
  final String slug;

  @override
  State<CategoryProductsPage> createState() => _CategoryProductsPageState();
}

class _CategoryProductsPageState extends State<CategoryProductsPage> {
  String _sortBy = 'featured';
  String _selectedSubCategory = 'all';
  CategoryFilterState _filterState = const CategoryFilterState();

  List<ProductEntity> _filterAndSort(List<ProductEntity> products) {
    var list = products;
    if (_selectedSubCategory != 'all') {
      list = list.where((p) =>
          p.category.toLowerCase() == _selectedSubCategory.toLowerCase()).toList();
    }
    list = applyCategoryFilters(list, _filterState);
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
    final result = await showFilterBottomSheet(context, initial: _filterState);
    if (result != null && mounted) setState(() => _filterState = result);
  }

  /// "clothing" and "accessories" are broad config slugs; products use specific categories (Dresses, Tops, etc).
  /// Don't pass these to the API—load by gender only, then filter by subcategory on client.
  String? _apiCategoryParam() {
    if (widget.slug.isEmpty) return null;
    if (widget.slug == 'clothing' || widget.slug == 'accessories') return null;
    return widget.slug;
  }

  @override
  void initState() {
    super.initState();
    context.read<ProductListBloc>().add(
          ProductListLoadRequested(
            gender: widget.gender,
            category: _apiCategoryParam(),
            limit: 200,
          ),
        );
  }

  @override
  void didUpdateWidget(CategoryProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gender != widget.gender || oldWidget.slug != widget.slug) {
      context.read<ProductListBloc>().add(
            ProductListLoadRequested(
              gender: widget.gender,
              category: _apiCategoryParam(),
              limit: 200,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Title: match React - category ? category capitalized : gender ? gender capitalized : 'All Products'
    final categoryTitle = widget.slug.isNotEmpty
        ? '${widget.slug[0].toUpperCase()}${widget.slug.substring(1)}'
        : widget.gender.isNotEmpty
            ? '${widget.gender[0].toUpperCase()}${widget.gender.substring(1)}'
            : 'All Products';
    // Subcategory pills: only when gender && !category (React logic)
    final showSubPills = widget.gender.isNotEmpty && widget.slug.isEmpty;
    final subCategories = widget.gender == 'women'
        ? _womenSubCategories
        : widget.gender == 'men'
            ? _menSubCategories
            : ['All'];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      bottomNavigationBar: const BottomNav(currentIndex: 1), // Categories tab active
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) {
          if (state is ProductListLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: ProductGridSkeleton(itemCount: 6),
            );
          }
          if (state is ProductListError) {
            return EmptyState(
              title: 'Something went wrong',
              subtitle: state.message,
              icon: Icons.error_outline,
            );
          }
          if (state is ProductListLoaded) {
            final products = _filterAndSort(state.products);
            // Match React: always show filter bar + QuickActions, even when empty
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFixedFilterBar(categoryTitle, products.length, showSubPills, subCategories),
                Expanded(
                  child: Stack(
                    children: [
                      if (products.isEmpty)
                        _buildCategoryEmptyState()
                      else
                        GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.5,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) => ProductGridTile(product: products[index]),
                        ),
                      QuickActions(
                        onFilterTap: _showFilterSheet,
                        onSortTap: _showSortSheet,
                      ),
                    ],
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

  /// Fixed filter bar (matches React: fixed below header, z-40, border-b)
  Widget _buildFixedFilterBar(
    String categoryTitle,
    int count,
    bool showSubPills,
    List<String> subCategories,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item count row: title (left) | count (right) - React: flex justify-between px-4 py-2
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor(context),
                  ),
                ),
                Text(
                  '$count items',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          // Subcategory pills: only when gender && !category
          if (showSubPills)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1))),
              ),
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
                            color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: selected ? Colors.white : AppTheme.foregroundColor(context).withValues(alpha: 0.7),
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
}
