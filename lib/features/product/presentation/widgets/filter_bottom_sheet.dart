import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product_entity.dart';

/// Applies [CategoryFilterState] to products.
List<ProductEntity> applyCategoryFilters(
  List<ProductEntity> products,
  CategoryFilterState filter,
) {
  return products.where((p) {
    if (filter.priceRange != 'all') {
      if (filter.priceRange == '0-50' && p.price >= 50) return false;
      if (filter.priceRange == '50-100' && (p.price < 50 || p.price >= 100)) return false;
      if (filter.priceRange == '100-200' && (p.price < 100 || p.price >= 200)) return false;
      if (filter.priceRange == '200-500' && (p.price < 200 || p.price >= 500)) return false;
      if (filter.priceRange == '500+' && p.price < 500) return false;
    }
    if (filter.size != 'all') {
      if (!p.sizes.any((s) => s.toLowerCase() == filter.size)) return false;
    }
    if (filter.color != 'all') {
      if (!p.colors.any((c) => c.toLowerCase() == filter.color)) return false;
    }
    return true;
  }).toList();
}

/// Filter state for category page.
class CategoryFilterState {
  const CategoryFilterState({
    this.priceRange = 'all',
    this.size = 'all',
    this.color = 'all',
  });

  final String priceRange;
  final String size;
  final String color;

  CategoryFilterState copyWith({
    String? priceRange,
    String? size,
    String? color,
  }) =>
      CategoryFilterState(
        priceRange: priceRange ?? this.priceRange,
        size: size ?? this.size,
        color: color ?? this.color,
      );
}

/// Modal bottom sheet for filters (Price, Size, Color). Matches React MobileCategoryPage.
Future<CategoryFilterState?> showFilterBottomSheet(
  BuildContext context, {
  required CategoryFilterState initial,
}) {
  return showModalBottomSheet<CategoryFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => _FilterBottomSheet(initial: initial),
  );
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({required this.initial});

  final CategoryFilterState initial;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late CategoryFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foregroundColor(context),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _state = const CategoryFilterState()),
                        child: Text(
                          'Clear All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Price Range', const [
                      ('all', 'All'),
                      ('0-50', 'Under \$50'),
                      ('50-100', '\$50 - \$100'),
                      ('100-200', '\$100 - \$200'),
                      ('200-500', '\$200 - \$500'),
                      ('500+', 'Over \$500'),
                    ], _state.priceRange, (v) => setState(() => _state = _state.copyWith(priceRange: v))),
                    const SizedBox(height: 24),
                    _buildSection('Size', const [
                      ('all', 'All'),
                      ('xs', 'XS'),
                      ('s', 'S'),
                      ('m', 'M'),
                      ('l', 'L'),
                      ('xl', 'XL'),
                      ('xxl', 'XXL'),
                    ], _state.size, (v) => setState(() => _state = _state.copyWith(size: v))),
                    const SizedBox(height: 24),
                    _buildSection('Color', const [
                      ('all', 'All'),
                      ('black', 'Black'),
                      ('white', 'White'),
                      ('red', 'Red'),
                      ('blue', 'Blue'),
                      ('green', 'Green'),
                    ], _state.color, (v) => setState(() => _state = _state.copyWith(color: v))),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.08))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_state),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    String title,
    List<(String value, String label)> options,
    String selectedValue,
    void Function(String) onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.foregroundColor(context),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final selected = selectedValue == o.$1;
            return GestureDetector(
              onTap: () => onSelect(o.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  o.$2,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
