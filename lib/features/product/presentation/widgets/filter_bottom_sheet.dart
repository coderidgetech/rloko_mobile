import 'package:flutter/material.dart';

import '../../../../core/constants/currency_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/product_entity.dart';

/// Returns the price of [p] in the active region's currency. India uses the INR
/// price (falling back to a converted USD value); everywhere else uses USD.
double Function(ProductEntity) priceSelector({required bool india}) {
  return (p) => india ? (p.priceInr ?? p.price * kUsdToInrDisplay) : p.price;
}

const _sizeOrder = ['xs', 's', 'm', 'l', 'xl', 'xxl', 'xxxl'];
int _sizeRank(String s) {
  final i = _sizeOrder.indexOf(s.toLowerCase());
  return i == -1 ? 999 : i;
}

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Filterable options derived from the products actually in the current list,
/// so the sheet only ever offers attributes that exist (and nothing that
/// returns zero results).
class FacetOptions {
  const FacetOptions({
    required this.sizes,
    required this.colors,
    required this.brands,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<String> sizes; // display labels, size-ordered
  final List<String> colors; // display labels, alphabetical
  final List<String> brands; // display labels, alphabetical
  final double minPrice; // in active currency
  final double maxPrice;

  bool get hasPriceRange => maxPrice > minPrice;

  static const empty = FacetOptions(
    sizes: [],
    colors: [],
    brands: [],
    minPrice: 0,
    maxPrice: 0,
  );
}

/// Derives the available facets from [products] using [priceOf] for the price range.
FacetOptions computeFacets(
  List<ProductEntity> products,
  double Function(ProductEntity) priceOf,
) {
  final sizes = <String, String>{}; // lowercase key -> display
  final colors = <String, String>{};
  final brands = <String, String>{};
  double? mn, mx;
  for (final p in products) {
    for (final s in p.sizes) {
      final k = s.trim();
      if (k.isNotEmpty) sizes.putIfAbsent(k.toLowerCase(), () => k.toUpperCase());
    }
    for (final c in p.colors) {
      final k = c.trim();
      if (k.isNotEmpty) colors.putIfAbsent(k.toLowerCase(), () => _capitalize(k));
    }
    final b = p.brand?.trim();
    if (b != null && b.isNotEmpty) brands.putIfAbsent(b.toLowerCase(), () => b);
    final pr = priceOf(p);
    if (pr > 0) {
      mn = (mn == null || pr < mn) ? pr : mn;
      mx = (mx == null || pr > mx) ? pr : mx;
    }
  }
  final sizeList = sizes.values.toList()
    ..sort((a, b) {
      final r = _sizeRank(a).compareTo(_sizeRank(b));
      return r != 0 ? r : a.compareTo(b);
    });
  final colorList = colors.values.toList()..sort();
  final brandList = brands.values.toList()..sort();
  return FacetOptions(
    sizes: sizeList,
    colors: colorList,
    brands: brandList,
    minPrice: (mn ?? 0).floorToDouble(),
    maxPrice: (mx ?? 0).ceilToDouble(),
  );
}

/// Applies [filter] to [products]. [priceOf] supplies each product's price in the
/// active currency so the price bounds compare like-for-like (fixes the IN market,
/// where the catalog is priced in ₹ but the old buckets were USD).
List<ProductEntity> applyCategoryFilters(
  List<ProductEntity> products,
  CategoryFilterState filter, {
  required double Function(ProductEntity) priceOf,
}) {
  if (filter.isEmpty) return products;
  return products.where((p) {
    final price = priceOf(p);
    if (filter.minPrice != null && price < filter.minPrice!) return false;
    if (filter.maxPrice != null && price > filter.maxPrice!) return false;
    if (filter.sizes.isNotEmpty &&
        !p.sizes.any((s) => filter.sizes.contains(s.toLowerCase()))) {
      return false;
    }
    if (filter.colors.isNotEmpty &&
        !p.colors.any((c) => filter.colors.contains(c.toLowerCase()))) {
      return false;
    }
    if (filter.brands.isNotEmpty) {
      final b = p.brand?.toLowerCase();
      if (b == null || !filter.brands.contains(b)) return false;
    }
    if (filter.minRating > 0 && p.rating < filter.minRating) return false;
    if (filter.onSaleOnly &&
        !(p.onSale || (p.originalPrice != null && p.originalPrice! > p.price))) {
      return false;
    }
    if (filter.inStockOnly &&
        !(p.stock.isEmpty || p.stock.values.any((q) => q > 0))) {
      return false;
    }
    return true;
  }).toList();
}

/// Multi-facet filter state for the product list / category pages.
class CategoryFilterState {
  const CategoryFilterState({
    this.sizes = const {},
    this.colors = const {},
    this.brands = const {},
    this.minPrice,
    this.maxPrice,
    this.minRating = 0,
    this.onSaleOnly = false,
    this.inStockOnly = false,
  });

  final Set<String> sizes; // lowercased
  final Set<String> colors; // lowercased
  final Set<String> brands; // lowercased
  final double? minPrice; // active currency; null = no bound
  final double? maxPrice;
  final double minRating; // 0 = any
  final bool onSaleOnly;
  final bool inStockOnly;

  bool get isEmpty =>
      sizes.isEmpty &&
      colors.isEmpty &&
      brands.isEmpty &&
      minPrice == null &&
      maxPrice == null &&
      minRating == 0 &&
      !onSaleOnly &&
      !inStockOnly;

  /// Number of active facet groups — drives the "Filter · N" badge.
  int get activeCount {
    var n = 0;
    if (sizes.isNotEmpty) n++;
    if (colors.isNotEmpty) n++;
    if (brands.isNotEmpty) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (minRating > 0) n++;
    if (onSaleOnly) n++;
    if (inStockOnly) n++;
    return n;
  }
}

/// Bottom sheet for refining a product list. Options come from [facets] (derived
/// from the current results), prices are labelled with [formatPrice].
Future<CategoryFilterState?> showFilterBottomSheet(
  BuildContext context, {
  required CategoryFilterState initial,
  required FacetOptions facets,
  required String Function(double) formatPrice,
}) {
  return showModalBottomSheet<CategoryFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => _FilterBottomSheet(
      initial: initial,
      facets: facets,
      formatPrice: formatPrice,
    ),
  );
}

class _FilterBottomSheet extends StatefulWidget {
  const _FilterBottomSheet({
    required this.initial,
    required this.facets,
    required this.formatPrice,
  });

  final CategoryFilterState initial;
  final FacetOptions facets;
  final String Function(double) formatPrice;

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _sizes;
  late Set<String> _colors;
  late Set<String> _brands;
  late RangeValues _price;
  late double _minRating;
  late bool _onSale;
  late bool _inStock;

  FacetOptions get _facets => widget.facets;

  @override
  void initState() {
    super.initState();
    _resetFrom(widget.initial);
  }

  void _resetFrom(CategoryFilterState s) {
    _sizes = {...s.sizes};
    _colors = {...s.colors};
    _brands = {...s.brands};
    _minRating = s.minRating;
    _onSale = s.onSaleOnly;
    _inStock = s.inStockOnly;
    _price = RangeValues(
      (s.minPrice ?? _facets.minPrice).clamp(_facets.minPrice, _facets.maxPrice),
      (s.maxPrice ?? _facets.maxPrice).clamp(_facets.minPrice, _facets.maxPrice),
    );
  }

  void _clearAll() => setState(() => _resetFrom(const CategoryFilterState()));

  CategoryFilterState _build() {
    final fullRange = _price.start <= _facets.minPrice &&
        _price.end >= _facets.maxPrice;
    return CategoryFilterState(
      sizes: _sizes,
      colors: _colors,
      brands: _brands,
      minPrice: fullRange ? null : _price.start,
      maxPrice: fullRange ? null : _price.end,
      minRating: _minRating,
      onSaleOnly: _onSale,
      inStockOnly: _inStock,
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppTheme.foregroundColor(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                      color: fg.withValues(alpha: 0.2),
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
                          color: fg,
                        ),
                      ),
                      GestureDetector(
                        onTap: _clearAll,
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
            Container(height: 1, color: fg.withValues(alpha: 0.08)),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_facets.hasPriceRange) ...[
                      _priceSection(fg),
                      const SizedBox(height: 24),
                    ],
                    if (_facets.sizes.isNotEmpty) ...[
                      _multiSection(
                        'Size',
                        _facets.sizes,
                        _sizes,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_facets.colors.isNotEmpty) ...[
                      _multiSection(
                        'Color',
                        _facets.colors,
                        _colors,
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (_facets.brands.isNotEmpty) ...[
                      _multiSection(
                        'Brand',
                        _facets.brands,
                        _brands,
                      ),
                      const SizedBox(height: 24),
                    ],
                    _ratingSection(fg),
                    const SizedBox(height: 24),
                    _toggleSection(fg),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: fg.withValues(alpha: 0.08))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_build()),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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

  Widget _sectionTitle(String title, Color fg) => Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: fg),
      );

  Widget _priceSection(Color fg) {
    final divisions = (_facets.maxPrice - _facets.minPrice).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _sectionTitle('Price', fg),
            Text(
              '${widget.formatPrice(_price.start)} – ${widget.formatPrice(_price.end)}',
              style: TextStyle(fontSize: 13, color: fg.withValues(alpha: 0.7)),
            ),
          ],
        ),
        RangeSlider(
          values: _price,
          min: _facets.minPrice,
          max: _facets.maxPrice,
          divisions: divisions > 0 ? (divisions > 100 ? 100 : divisions) : null,
          activeColor: AppTheme.primaryColor(context),
          labels: RangeLabels(
            widget.formatPrice(_price.start),
            widget.formatPrice(_price.end),
          ),
          onChanged: (v) => setState(() => _price = v),
        ),
      ],
    );
  }

  Widget _multiSection(String title, List<String> options, Set<String> selected) {
    final fg = AppTheme.foregroundColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(title, fg),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((label) {
            final key = label.toLowerCase();
            final isSel = selected.contains(key);
            return GestureDetector(
              onTap: () => setState(() {
                if (isSel) {
                  selected.remove(key);
                } else {
                  selected.add(key);
                }
              }),
              child: _chip(label, isSel, fg),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _ratingSection(Color fg) {
    const options = [(0.0, 'Any'), (3.0, '3★ & up'), (4.0, '4★ & up'), (4.5, '4.5★ & up')];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Rating', fg),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((o) {
            final isSel = _minRating == o.$1;
            return GestureDetector(
              onTap: () => setState(() => _minRating = o.$1),
              child: _chip(o.$2, isSel, fg),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _toggleSection(Color fg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Show only', fg),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            GestureDetector(
              onTap: () => setState(() => _onSale = !_onSale),
              child: _chip('On sale', _onSale, fg),
            ),
            GestureDetector(
              onTap: () => setState(() => _inStock = !_inStock),
              child: _chip('In stock', _inStock, fg),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, bool selected, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primaryColor(context)
              : fg.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : fg.withValues(alpha: 0.7),
          ),
        ),
      );
}
