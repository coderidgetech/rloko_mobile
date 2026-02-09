import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductDetailBloc(
        getProductByIdUseCase: sl<GetProductByIdUseCase>(),
      )..add(ProductDetailLoadRequested(productId)),
      child: _ProductDetailView(productId: productId),
    );
  }
}

class _ProductDetailView extends StatefulWidget {
  const _ProductDetailView({required this.productId});

  final String productId;

  @override
  State<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<_ProductDetailView> {
  int _imageIndex = 0;
  String? _selectedSize;
  int _quantity = 1;
  String _expandedSection = '';
  bool _hasRequestedRecommendations = false;
  double _dragStartX = 0;
  double _dragEndX = 0;

  void _showSizeChartDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Size Guide'),
        content: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Size')),
              DataColumn(label: Text('Chest')),
              DataColumn(label: Text('Waist')),
              DataColumn(label: Text('Hip')),
            ],
            rows: const [
              DataRow(cells: [
                DataCell(Text('XS')),
                DataCell(Text('32-34')),
                DataCell(Text('26-28')),
                DataCell(Text('34-36')),
              ]),
              DataRow(cells: [
                DataCell(Text('S')),
                DataCell(Text('34-36')),
                DataCell(Text('28-30')),
                DataCell(Text('36-38')),
              ]),
              DataRow(cells: [
                DataCell(Text('M')),
                DataCell(Text('36-38')),
                DataCell(Text('30-32')),
                DataCell(Text('38-40')),
              ]),
              DataRow(cells: [
                DataCell(Text('L')),
                DataCell(Text('38-40')),
                DataCell(Text('32-34')),
                DataCell(Text('40-42')),
              ]),
              DataRow(cells: [
                DataCell(Text('XL')),
                DataCell(Text('40-42')),
                DataCell(Text('34-36')),
                DataCell(Text('42-44')),
              ]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Match React: display $ price (text-2xl font-bold / text-base line-through)
  String _formatPrice(ProductEntity p) => '\$${p.price.toStringAsFixed(2)}';
  String _formatOriginalPrice(ProductEntity p) =>
      p.originalPrice != null ? '\$${p.originalPrice!.toStringAsFixed(2)}' : '';

  void _toggleSection(String section) {
    setState(() => _expandedSection = _expandedSection == section ? '' : section);
  }

  static String _deliveryDateStr() {
    final d = DateTime.now().add(const Duration(days: 5));
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  /// Match React: Standard = left col STANDARD + date, right col crossed + green price; green cards = bg #F0FDF4
  Widget _deliveryCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? crossed,
    String? price,
    bool isGreen = false,
  }) {
    const greenBg = Color(0xFFF0FDF4);
    const greenColor = Color(0xFF16A34A);
    return Container(
      padding: EdgeInsets.all(isGreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isGreen ? greenBg : null,
        border: isGreen ? null : Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isGreen ? greenColor : AppTheme.foreground.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: crossed != null && price != null
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle!,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            crossed,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.foreground.withValues(alpha: 0.4),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: greenColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.6)),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// Match React: py-3 border-t border-b border-border, Plus icon rotates when expanded
  Widget _mobileAccordion(String id, String title, {Widget? headerTrailing, required Widget child}) {
    final isExpanded = _expandedSection == id;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
          bottom: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.12)),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (headerTrailing != null) ...[const SizedBox(width: 8), headerTrailing!],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.add, size: 20, color: AppTheme.foreground),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Match React: pb-4 border-b border-border/50 (except last), text-sm foreground/70, date text-xs foreground/40
  Widget _reviewItem(String name, int stars, String text, String date, {bool showBorder = true}) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.5))),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  size: 12,
                  color: i < stars ? AppTheme.primary : AppTheme.foreground.withValues(alpha: 0.2),
                )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.7), height: 1.5),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.4)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state is ProductDetailLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is ProductDetailError) {
            return EmptyState(
              title: 'Product not found',
              subtitle: state.message,
              icon: Icons.error_outline,
              actionLabel: 'Back to Shop',
              onAction: () => context.go('/'),
            );
          }
          if (state is! ProductDetailLoaded) return const SizedBox.shrink();
          final product = state.product;
          if (!_hasRequestedRecommendations) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _hasRequestedRecommendations = true);
              context.read<ProductListBloc>().add(const ProductListLoadRequested(limit: 200));
            });
          }
          final images = product.images.isEmpty
              ? <String>[placeholderImageUrl]
              : product.images;
          final isInCart = context.read<CartBloc>().state is CartLoaded &&
              (context.read<CartBloc>().state as CartLoaded)
                  .cart
                  .items
                  .any((i) => i.productId == product.id);
          final isWishlisted = context.read<WishlistBloc>().state is WishlistLoaded &&
              (context.read<WishlistBloc>().state as WishlistLoaded)
                  .items
                  .any((i) => i.productId == product.id);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image gallery - match React: full-bleed, aspect 3/4, swipeable, dots bottom-4 gap-1.5, rating badge, thumbnails flex gap-2 px-4 py-3
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Main image container: relative aspect-[3/4] bg-muted overflow-hidden
                    GestureDetector(
                      onHorizontalDragStart: (d) => _dragStartX = d.globalPosition.dx,
                      onHorizontalDragUpdate: (d) => _dragEndX = d.globalPosition.dx,
                      onHorizontalDragEnd: (DragEndDetails _) {
                        final distance = _dragStartX - _dragEndX;
                        if (distance > 50 && _imageIndex < images.length - 1) {
                          setState(() => _imageIndex++);
                        } else if (distance < -50 && _imageIndex > 0) {
                          setState(() => _imageIndex--);
                        }
                        _dragStartX = 0;
                        _dragEndX = 0;
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: double.infinity,
                            color: AppTheme.muted,
                            child: AspectRatio(
                              aspectRatio: 3 / 4,
                              child: CachedNetworkImage(
                                imageUrl: safeImageUrl(images[_imageIndex.clamp(0, images.length - 1)]),
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppTheme.muted,
                                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppTheme.muted,
                                  child: const Icon(Icons.image_not_supported, size: 64),
                                ),
                              ),
                            ),
                          ),
                          // Wishlist button (match React: heart on image so user can add to wishlist from any page)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                onTap: () {
                                  if (isWishlisted) {
                                    context.read<WishlistBloc>().add(WishlistRemoveItemRequested(product.id));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Removed from wishlist')),
                                    );
                                  } else {
                                    context.read<WishlistBloc>().add(WishlistAddItemRequested(
                                          product.id,
                                          productName: product.name,
                                          productImage: product.firstImage,
                                          productPrice: product.price,
                                        ));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Added to wishlist')),
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(24),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Icon(
                                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                                    size: 22,
                                    color: isWishlisted ? AppTheme.primary : AppTheme.foreground,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Image indicators: absolute bottom-4 left-0 right-0 flex center gap-1.5, h-1.5 rounded-full, selected w-6 bg-white else w-1.5 bg-white/50
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => GestureDetector(
                                  onTap: () => setState(() => _imageIndex = i),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: i == _imageIndex ? 24 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: i == _imageIndex ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Rating badge: absolute bottom-4 right-4, only when product.rating
                          if (product.rating > 0)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${product.rating}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.star, size: 14, color: AppTheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      '|',
                                      style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5)),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product.reviews}',
                                      style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.6)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Thumbnail strip: flex gap-2 px-4 py-3 overflow-x-auto (always show when there are images)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: Colors.white,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children: List.generate(
                              images.length,
                              (i) => Padding(
                                padding: EdgeInsets.only(right: i < images.length - 1 ? 8 : 0),
                                child: GestureDetector(
                                  onTap: () => setState(() => _imageIndex = i),
                                  child: Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: i == _imageIndex ? AppTheme.primary : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: CachedNetworkImage(
                                      imageUrl: safeImageUrl(images[i]),
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppTheme.muted,
                                        child: const Icon(Icons.image),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),  // image gallery Column
                // Product info (match React mobile: title, category, price, size, Buy Now + Add to Bag)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & category
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                      // Price row (match React: $price, strikethrough, % OFF badge)
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatPrice(product),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                            const SizedBox(width: 12),
                            Text(
                              _formatOriginalPrice(product),
                              style: TextStyle(
                                fontSize: 16,
                                color: AppTheme.foreground.withValues(alpha: 0.4),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()}% OFF',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      // Size (match React: "Size: X", Size Chart link, recommended badge, grid 4 cols rounded-xl)
                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Size: ${_selectedSize ?? '—'}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (_selectedSize != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'Garment Measurement: Chest 41.0in',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.foreground.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => _showSizeChartDialog(context),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Size Chart'),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right, size: 18, color: AppTheme.primary),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_selectedSize == null && product.sizes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Size ${product.sizes[product.sizes.length ~/ 2]} Recommended',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 4,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.2,
                          children: product.sizes.map((size) {
                            final selected = _selectedSize == size;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _selectedSize = size),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: selected ? AppTheme.foreground : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected ? AppTheme.foreground : AppTheme.border,
                                      width: 2,
                                    ),
                                  ),
                                  child: Text(
                                    size,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: selected ? AppTheme.background : AppTheme.foreground,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      // Buy Now + Add to Bag (match React)
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (product.sizes.isNotEmpty && _selectedSize == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a size')),
                                  );
                                  return;
                                }
                                final size = _selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.first : 'One Size');
                                context.read<CartBloc>().add(CartAddItemRequested(
                                      CartItemEntity(
                                        productId: product.id,
                                        productName: product.name,
                                        image: product.firstImage ?? '',
                                        price: product.price,
                                        priceInr: product.priceInr,
                                        size: size,
                                        quantity: _quantity,
                                      ),
                                    ));
                                context.push('/cart');
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.primary,
                                side: const BorderSide(color: AppTheme.primary, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shopping_bag_outlined, size: 18),
                                  SizedBox(width: 8),
                                  Text('Buy Now'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                if (isInCart) {
                                  context.push('/cart');
                                  return;
                                }
                                if (product.sizes.isNotEmpty && _selectedSize == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a size')),
                                  );
                                  return;
                                }
                                final size = _selectedSize ?? (product.sizes.isNotEmpty ? product.sizes.first : 'One Size');
                                context.read<CartBloc>().add(CartAddItemRequested(
                                      CartItemEntity(
                                        productId: product.id,
                                        productName: product.name,
                                        image: product.firstImage ?? '',
                                        price: product.price,
                                        priceInr: product.priceInr,
                                        size: size,
                                        quantity: _quantity,
                                      ),
                                    ));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Added to bag')),
                                );
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: AppTheme.primaryForeground,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isInCart ? Icons.shopping_bag : Icons.shopping_bag_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(isInCart ? 'Go to Bag' : 'Add to Bag'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Delivery & Services (match React)
                      const SizedBox(height: 24),
                      const Text(
                        'Delivery & Services',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // React: p-4 bg-foreground/5 rounded-xl, MapPin 18, "Change" text-primary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.foreground.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 18, color: AppTheme.foreground.withValues(alpha: 0.6)),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Select delivery address',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              'Change',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _deliveryCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'STANDARD',
                        subtitle: 'Delivery by ${_deliveryDateStr()}',
                        crossed: '₹2099',
                        price: '₹671 (68% OFF)',
                        isGreen: false,
                      ),
                      const SizedBox(height: 12),
                      _deliveryCard(
                        icon: Icons.credit_card_outlined,
                        title: 'Pay on Delivery is available',
                        subtitle: '₹10 additional fee applicable',
                        isGreen: true,
                      ),
                      const SizedBox(height: 12),
                      _deliveryCard(
                        icon: Icons.swap_horiz,
                        title: 'Hassle free 7 days Return & Exchange',
                        isGreen: true,
                      ),
                      // Accordions: Description, Product Details, Customer Reviews (match React)
                      const SizedBox(height: 24),
                      _mobileAccordion(
                        'description',
                        'Description',
                        child: Text(
                          product.description.isEmpty
                              ? 'Crafted with meticulous attention to detail.'
                              : product.description,
                          style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.7), height: 1.5),
                        ),
                      ),
                      _mobileAccordion(
                        'details',
                        'Product Details',
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 16),
                          child: Column(
                            children: [
                              _productDetailRow('Material', product.material.isEmpty ? '100% Cotton' : product.material),
                              const SizedBox(height: 12),
                              _productDetailRow('Care Instructions', 'Machine Wash'),
                              const SizedBox(height: 12),
                              _productDetailRow('Country of Origin', 'USA'),
                              const SizedBox(height: 12),
                              _productDetailRow('SKU', 'RL-${product.id}'),
                            ],
                          ),
                        ),
                      ),
                      _mobileAccordion(
                        'reviews',
                        'Customer Reviews',
                        headerTrailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${product.rating}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _reviewItem('Sarah M.', 5, 'Absolutely love this piece! The quality is amazing and fits perfectly. Highly recommend!', '2 days ago', showBorder: true),
                            _reviewItem('Emma R.', 5, 'Great product! True to size and very comfortable. Will definitely buy again.', '1 week ago', showBorder: true),
                            _reviewItem('Jessica L.', 4, 'Beautiful design and good quality. Runs slightly small, consider sizing up.', '2 weeks ago', showBorder: false),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                                child: Text(
                                  'View All Reviews (${product.reviews})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Recommendations (match React: You May Also Like, Similar, Trending, Complete the Look)
                      BlocBuilder<ProductListBloc, ProductListState>(
                        builder: (context, listState) {
                          if (listState is! ProductListLoaded) return const SizedBox(height: 80);
                          final all = listState.products;
                          final youMayAlsoLike = all
                              .where((p) => p.id != product.id && p.category == product.category)
                              .take(10)
                              .toList();
                          final similar = all
                              .where((p) =>
                                  p.id != product.id &&
                                  p.category != product.category &&
                                  (p.price - product.price).abs() < 100)
                              .take(10)
                              .toList();
                          final trending = all
                              .where((p) {
                                final relatedIds = youMayAlsoLike.map((e) => e.id).toSet();
                                return p.id != product.id &&
                                    (p.rating >= 4.5) &&
                                    !relatedIds.contains(p.id);
                              })
                              .take(10)
                              .toList();
                          final completeLook = all
                              .where((p) =>
                                  p.id != product.id &&
                                  (p.price - product.price).abs() < 50 &&
                                  p.category != product.category)
                              .take(3)
                              .toList();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _recommendationSection(
                                context,
                                title: 'You May Also Like',
                                subtitle: 'Handpicked recommendations just for you',
                                icon: Icons.favorite,
                                products: youMayAlsoLike,
                              ),
                              _recommendationSection(
                                context,
                                title: 'Similar Products',
                                subtitle: 'Explore similar styles',
                                icon: Icons.auto_awesome,
                                products: similar,
                              ),
                              _recommendationSection(
                                context,
                                title: 'Trending Now',
                                subtitle: 'Most loved by our customers',
                                icon: Icons.trending_up,
                                products: trending,
                              ),
                              _completeTheLookSection(context, product, completeLook),
                              const SizedBox(height: 128),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _recommendationSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ProductEntity> products,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 20, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {},
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View All', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary)),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SizedBox(
            height: 320,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length + 1,
              itemBuilder: (context, index) {
                if (index == products.length) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: SizedBox(
                      width: 160,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primary.withValues(alpha: 0.1),
                              AppTheme.primary.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chevron_right, size: 32, color: AppTheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'View All',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primary),
                            ),
                            Text(
                              '${products.length} products',
                              style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final p = products[index];
                return Padding(
                  padding: EdgeInsets.only(right: index < products.length - 1 ? 12 : 0),
                  child: _productCard(context, p, 160),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(BuildContext context, ProductEntity p, double width) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: () => context.push('/product/${p.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CachedNetworkImage(
                  imageUrl: safeImageUrl(p.firstImage ?? ''),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.muted,
                    child: const Icon(Icons.image),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (p.rating > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star, size: 12, color: AppTheme.primary),
                  const SizedBox(width: 4),
                  Text('${p.rating}', style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.6))),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '\$${p.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primary),
                ),
                if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                  const SizedBox(width: 6),
                  Text(
                    '\$${p.originalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.4), decoration: TextDecoration.lineThrough),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _completeTheLookSection(
    BuildContext context,
    ProductEntity currentProduct,
    List<ProductEntity> completeLook,
  ) {
    final allProducts = [currentProduct, ...completeLook].take(4).toList();
    if (allProducts.length <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Complete the Look',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bundle and save 10% on your purchase',
                  style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final p = allProducts[index];
              final isMain = p.id == currentProduct.id;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMain ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMain ? AppTheme.primary : Colors.white,
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: isMain ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: CachedNetworkImage(
                          imageUrl: safeImageUrl(p.firstImage ?? ''),
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.muted,
                            child: const Icon(Icons.image),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.category,
                            style: TextStyle(fontSize: 12, color: AppTheme.foreground.withValues(alpha: 0.5)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${p.price.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primary),
                          ),
                        ],
                      ),
                    ),
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Subtotal (${allProducts.length} items)', style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6))),
                      Text(
                        '\$${allProducts.fold<double>(0, (s, p) => s + p.price).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bundle Discount (10%)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
                      Text(
                        '-\$${(allProducts.fold<double>(0, (s, p) => s + p.price) * 0.1).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppTheme.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${(allProducts.fold<double>(0, (s, p) => s + p.price) * 0.9).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                          Text(
                            'You save \$${(allProducts.fold<double>(0, (s, p) => s + p.price) * 0.1).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF16A34A)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.shopping_bag, size: 20),
                      label: const Text('Add Bundle to Cart'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.primaryForeground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  '✨ Free shipping on orders over \$50',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF166534)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlight(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.foreground.withValues(alpha: 0.1)),
          ),
          child: Icon(icon, size: 18, color: AppTheme.mutedForeground),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(fontSize: 12, letterSpacing: 1, color: AppTheme.mutedForeground),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _deliveryRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.foreground.withValues(alpha: 0.4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14)),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _accordion(String id, IconData icon, String title, {required Widget child}) {
    final isExpanded = _expandedSection == id;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.foreground.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.mutedForeground),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more, size: 18, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.foreground.withValues(alpha: 0.1))),
              ),
              child: child,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
          children: [
            TextSpan(
              text: '${label.toUpperCase()}: ',
              style: const TextStyle(
                color: AppTheme.foreground,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// Match React Product Details: flex justify-between text-sm, left foreground/60, right font-medium
  static Widget _productDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppTheme.foreground.withValues(alpha: 0.6)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  static Widget _sustainRow(IconData icon, String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedForeground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _faqItem(String q, String a) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          q,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          a,
          style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground, height: 1.5),
        ),
      ],
    );
  }
}
