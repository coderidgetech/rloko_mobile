import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../widgets/product_grid_skeleton.dart';
import '../widgets/product_grid_tile.dart';
import '../widgets/sort_bottom_sheet.dart';
import '../../domain/entities/product_entity.dart';

/// Filter pill for New Arrivals: value (category slug) and label.
class FilterPill {
  const FilterPill({required this.value, required this.label});
  final String value;
  final String label;
}

/// Reusable product list page. Matches React mobile: AppHeader, stats bar, Sort bottom sheet.
/// Optional filter pills (New Arrivals), sale banner (Sale page).
class ProductListPage extends StatefulWidget {
  const ProductListPage({
    super.key,
    required this.title,
    required this.loadEvent,
    this.sortOptions = const [
      SortOption(value: 'newest', label: 'Newest First'),
      SortOption(value: 'price-low', label: 'Price: Low to High'),
      SortOption(value: 'price-high', label: 'Price: High to Low'),
    ],
    this.initialSort = 'newest',
    this.filterPills,
    this.statsLabel = 'Showing %d products',
    this.showSaleBanner = false,
    this.emptyTitle = 'No products',
  });

  final String title;
  final ProductListEvent loadEvent;
  final List<SortOption> sortOptions;
  final String initialSort;
  final List<FilterPill>? filterPills;
  final String statsLabel; // Use %d for count
  final bool showSaleBanner;
  final String emptyTitle;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  late String _sortBy;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _sortBy = widget.initialSort;
    context.read<ProductListBloc>().add(widget.loadEvent);
  }

  List<ProductEntity> _filterAndSort(List<ProductEntity> products) {
    var list = products;
    if (widget.filterPills != null && _selectedFilter != 'all') {
      list = list.where((p) =>
          p.category.toLowerCase() == _selectedFilter.toLowerCase()).toList();
    }
    list = List.from(list);
    if (_sortBy == 'price-low') {
      list.sort((a, b) => a.price.compareTo(b.price));
    } else if (_sortBy == 'price-high') {
      list.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'newest') {
      list.sort((a, b) => (b.newArrival ? 1 : 0).compareTo(a.newArrival ? 1 : 0));
    } else if (_sortBy == 'discount') {
      list.sort((a, b) {
        final origA = a.originalPrice ?? a.price;
        final origB = b.originalPrice ?? b.price;
        final discA = origA > 0 ? ((origA - a.price) / origA) * 100 : 0.0;
        final discB = origB > 0 ? ((origB - b.price) / origB) * 100 : 0.0;
        return discB.compareTo(discA);
      });
    } else if (_sortBy == 'featured') {
      list.sort((a, b) => (b.featured ? 1 : 0).compareTo(a.featured ? 1 : 0));
    }
    return list;
  }

  Future<void> _showSortSheet() async {
    final result = await showSortBottomSheet(
      context,
      options: widget.sortOptions,
      selectedValue: _sortBy,
    );
    if (result != null && mounted) setState(() => _sortBy = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        buildWhen: (prev, next) => next is ProductListLoaded || next is ProductListLoading || next is ProductListError || next is ProductListInitial,
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
              actionLabel: 'Try Again',
              onAction: () => context.read<ProductListBloc>().add(widget.loadEvent),
            );
          }
          if (state is ProductListLoaded) {
            final products = _filterAndSort(state.products);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showSaleBanner) _buildSaleBanner(state.products.length),
                if (widget.filterPills != null) _buildFilterPills(),
                _buildStatsBar(products.length),
                Expanded(
                  child: products.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.5, // Match React: 3/4 image + info block
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) =>
                        ProductGridTile(key: ValueKey(products[index].id), product: products[index]),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
  }

  Widget _buildSaleBanner(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.shade50,
            Colors.orange.shade50,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Limited Time Offer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Up to 70% off on selected items',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  Text(
                    'Items',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _showSortSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune, size: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        'Sort',
                        style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final pills = widget.filterPills!;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: pills.map((p) {
            final selected = _selectedFilter == p.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = p.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  p.label,
                  style: TextStyle(
                    fontSize: 12,
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
    );
  }

  Widget _buildEmptyState() {
    final isNewArrivals = widget.emptyTitle == 'No new arrivals';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isNewArrivals ? Icons.auto_awesome : Icons.grid_view,
              size: 48,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppTheme.foregroundColor(context),
              ),
            ),
            if (isNewArrivals) ...[
              const SizedBox(height: 8),
              Text(
                'Check back soon for new items in this category',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsBar(int count) {
    if (widget.showSaleBanner) return const SizedBox.shrink();
    final label = widget.statsLabel.replaceAll('%d', '$count');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.foregroundColor(context).withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
            ),
          ),
          GestureDetector(
            onTap: _showSortSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    'Sort',
                    style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
