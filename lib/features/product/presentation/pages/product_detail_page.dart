import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/delivery_constants.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/delivery_location_strip.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../data/datasources/product_local_datasource.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/usecases/get_product_by_id_usecase.dart';
import '../../domain/usecases/get_recommendations_usecase.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/product_list_bloc.dart';
import '../widgets/empty_state.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';
import '../../../review/domain/entities/review_entity.dart';
import '../../../review/domain/usecases/get_product_reviews_usecase.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ProductDetailBloc(getProductByIdUseCase: sl<GetProductByIdUseCase>())
            ..add(ProductDetailLoadRequested(productId)),
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
  List<ProductEntity> _apiRecommendations = [];
  bool _productReviewsRequestStarted = false;
  List<ProductReviewEntity> _productReviews = [];
  int _productReviewsTotal = 0;
  bool _productReviewsLoading = false;
  String? _productReviewsError;
  int _reviewPage = 0;
  bool _reviewsHasMore = true;
  bool _reviewsLoadingMore = false;
  ProductEntity? _loadedProduct;
  late final PageController _pageController;
  Timer? _imageTimer;
  int _timerImageCount = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _imageTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startImageTimer(int count) {
    if (count <= 1) { _imageTimer?.cancel(); return; }
    if (count == _timerImageCount && _imageTimer != null && _imageTimer!.isActive) return;
    _timerImageCount = count;
    _imageTimer?.cancel();
    _imageTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_imageIndex + 1) % _timerImageCount;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

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
              DataRow(
                cells: [
                  DataCell(Text('XS')),
                  DataCell(Text('32-34')),
                  DataCell(Text('26-28')),
                  DataCell(Text('34-36')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('S')),
                  DataCell(Text('34-36')),
                  DataCell(Text('28-30')),
                  DataCell(Text('36-38')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('M')),
                  DataCell(Text('36-38')),
                  DataCell(Text('30-32')),
                  DataCell(Text('38-40')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('L')),
                  DataCell(Text('38-40')),
                  DataCell(Text('32-34')),
                  DataCell(Text('40-42')),
                ],
              ),
              DataRow(
                cells: [
                  DataCell(Text('XL')),
                  DataCell(Text('40-42')),
                  DataCell(Text('34-36')),
                  DataCell(Text('42-44')),
                ],
              ),
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

  /// Match React: display price in selected region (USD/INR)
  String _formatPrice(BuildContext context, ProductEntity p) =>
      CurrencyScope.of(context).formatPrice(p.price, p.priceInr);
  String _formatOriginalPrice(BuildContext context, ProductEntity p) =>
      p.originalPrice != null
      ? CurrencyScope.of(context).formatPrice(p.originalPrice!, null)
      : '';

  void _toggleSection(String section) {
    setState(
      () => _expandedSection = _expandedSection == section ? '' : section,
    );
  }

  Future<void> _loadProductReviews(String id) async {
    if (_productReviewsLoading) return;
    setState(() {
      _productReviewsLoading = true;
      _productReviewsError = null;
      _reviewPage = 0;
    });
    try {
      final r = await sl<GetProductReviewsUseCase>()(id, limit: 10, skip: 0);
      if (!mounted) return;
      setState(() {
        _productReviews = r.reviews;
        _productReviewsTotal = r.total;
        _reviewsHasMore = r.total > r.reviews.length;
        _productReviewsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productReviewsError = e.toString();
        _productReviewsLoading = false;
        _productReviews = [];
        _productReviewsTotal = 0;
        _reviewsHasMore = false;
      });
    }
  }

  Future<void> _loadMoreReviews(String id) async {
    if (!_reviewsHasMore || _reviewsLoadingMore) return;
    setState(() => _reviewsLoadingMore = true);
    _reviewPage++;
    try {
      final r = await sl<GetProductReviewsUseCase>()(
        id,
        limit: 10,
        skip: _reviewPage * 10,
      );
      if (!mounted) return;
      setState(() {
        _productReviews = [..._productReviews, ...r.reviews];
        _reviewsHasMore = _productReviews.length < _productReviewsTotal;
        _reviewsLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      _reviewPage--;
      setState(() => _reviewsLoadingMore = false);
    }
  }

  static const String _emDash = '—';
  static const double _bundleDiscountRate = 0.10;
  static const String _oneSizeFallback = 'One Size';
  static const Color _successGreen = Color(0xFF16A34A);
  static const Color _successGreenBg = Color(0xFFF0FDF4);

  /// Mean of loaded approved reviews; count uses API total.
  double _averageReviewRating() {
    if (_productReviews.isEmpty) return 0;
    var s = 0;
    for (final r in _productReviews) {
      s += r.rating;
    }
    return s / _productReviews.length;
  }

  String _ratingLabel() {
    final v = _averageReviewRating();
    if (v <= 0) {
      return '0';
    }
    if ((v * 10).round() % 10 == 0) {
      return v.toStringAsFixed(0);
    }
    return v.toStringAsFixed(1);
  }

  /// Hide seeded product.rating; show only after review API result with at least one approved review.
  bool _showProductRatingUI() {
    if (_productReviewsLoading) {
      return false;
    }
    if (_productReviewsError != null) {
      return false;
    }
    return _productReviewsTotal > 0;
  }

  String _careFromProduct(ProductEntity p) {
    for (final d in p.details) {
      if (RegExp('wash|dry|clean|iron|care', caseSensitive: false).hasMatch(d)) {
        return d;
      }
    }
    if (p.details.isNotEmpty) {
      return p.details.first;
    }
    return _emDash;
  }

  static String _formatReviewDate(DateTime? t) {
    if (t == null) {
      return '';
    }
    return DateFormat.yMMMd().format(t.toLocal());
  }

  Widget _reviewBlockFromDto(ProductReviewEntity r, {bool showBorder = true}) {
    final text = [
      if (r.title.trim().isNotEmpty) r.title.trim(),
      r.comment.trim(),
    ].where((s) => s.isNotEmpty).join('\n\n');
    return _reviewItem(
      r.userName,
      r.rating,
      text.isNotEmpty ? text : '—',
      _formatReviewDate(r.createdAt),
      showBorder: showBorder,
    );
  }

  void _openAllProductReviewsSheet(BuildContext context, String productId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.extentAfter < 200) {
                  _loadMoreReviews(productId).then((_) => setSheetState(() {}));
                }
                return false;
              },
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.foregroundColor(ctx).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'All reviews ($_productReviewsTotal)',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  for (var i = 0; i < _productReviews.length; i++)
                    _reviewBlockFromDto(
                      _productReviews[i],
                      showBorder: i < _productReviews.length - 1,
                    ),
                  if (_reviewsHasMore) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: _reviewsLoadingMore
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => _loadMoreReviews(productId)
                                  .then((_) => setSheetState(() {})),
                              child: const Text('Load more'),
                            ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductReviewsBody(BuildContext context, String productId) {
    if (_productReviewsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_productReviewsError != null) {
      return Text(
        'Could not load reviews.',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.destructive,
        ),
      );
    }
    if (_productReviews.isEmpty) {
      return Text(
        'No published reviews yet for this product.',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
        ),
      );
    }
    final preview = _productReviews.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < preview.length; i++)
          _reviewBlockFromDto(
            preview[i],
            showBorder: i < preview.length - 1,
          ),
        if (_productReviewsTotal > 3) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _openAllProductReviewsSheet(context, productId),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor(context),
              ),
              child: Text('View all ($_productReviewsTotal)'),
            ),
          ),
        ],
      ],
    );
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
    return Container(
      padding: EdgeInsets.all(isGreen ? 12 : 16),
      decoration: BoxDecoration(
        color: isGreen ? _successGreenBg : null,
        border: isGreen
            ? null
            : Border.all(color: AppTheme.borderColor(context)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isGreen
                ? _successGreen
                : AppTheme.foregroundColor(context).withValues(alpha: 0.6),
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
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
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
                              color: AppTheme.foregroundColor(
                                context,
                              ).withValues(alpha: 0.4),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          Text(
                            price,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _successGreen,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.foregroundColor(
                              context,
                            ).withValues(alpha: 0.6),
                          ),
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
  Widget _mobileAccordion(
    String id,
    String title, {
    Widget? headerTrailing,
    required Widget child,
  }) {
    final isExpanded = _expandedSection == id;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
          ),
          bottom: BorderSide(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
          ),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (headerTrailing != null) ...[
                    const SizedBox(width: 8),
                    headerTrailing,
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.add,
                      size: 20,
                      color: AppTheme.foregroundColor(context),
                    ),
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
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// Match React: pb-4 border-b border-border/50 (except last), text-sm foreground/70, date text-xs foreground/40
  Widget _reviewItem(
    String name,
    int stars,
    String text,
    String date, {
    bool showBorder = true,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: showBorder
          ? BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor(context).withValues(alpha: 0.5),
                ),
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < stars ? Icons.star : Icons.star_border,
                    size: 12,
                    color: i < stars
                        ? AppTheme.primaryColor(context)
                        : AppTheme.foregroundColor(
                            context,
                          ).withValues(alpha: 0.2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.7),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductDetailBloc, ProductDetailState>(
      listenWhen: (_, next) => next is ProductDetailLoaded,
      listener: (context, state) {
        if (state is ProductDetailLoaded) {
          setState(() => _loadedProduct = state.product);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: AppHeader(
          showBackButton: true,
          extraActions: _loadedProduct != null
              ? [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share',
                    onPressed: () {
                      Share.share(
                        'https://rloko.com/products/${_loadedProduct!.id}',
                        subject: _loadedProduct!.name,
                      );
                    },
                  ),
                ]
              : null,
        ),
        body: Column(
          children: [
            const DeliveryLocationStrip(),
            Expanded(
              child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
                buildWhen: (prev, next) => next is ProductDetailLoaded || next is ProductDetailLoading || next is ProductDetailError,
                builder: (context, state) {
                if (state is ProductDetailLoading) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
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
                if (state is! ProductDetailLoaded)
                  return const SizedBox.shrink();
                final product = state.product;
                if (!_hasRequestedRecommendations) {
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
                    setState(() => _hasRequestedRecommendations = true);
                    context.read<ProductListBloc>().add(
                      const ProductListLoadRequested(limit: 200),
                    );
                    try {
                      final recs = await sl<GetRecommendationsUseCase>()(product.id);
                      if (mounted) setState(() => _apiRecommendations = recs);
                    } catch (_) {}
                  });
                }
                if (!_productReviewsRequestStarted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() => _productReviewsRequestStarted = true);
                    _loadProductReviews(product.id);
                  });
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  sl<ProductLocalDataSource>().recordView(product.id);
                });
                final productImages = product.images;
                final hasProductImages = productImages.isNotEmpty;
                final images = hasProductImages ? productImages : <String>[];
                if (images.length > 1 && images.length != _timerImageCount) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) { if (mounted) _startImageTimer(images.length); },
                  );
                }
                final isWishlisted = context.select<WishlistBloc, bool>((bloc) {
                  final s = bloc.state;
                  if (s is! WishlistLoaded) return false;
                  return s.items.any((i) => i.productId == product.id);
                });

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image gallery - match React: full-bleed, aspect 3/4, swipeable, dots bottom-4 gap-1.5, rating badge, thumbnails flex gap-2 px-4 py-3
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Main image container: relative aspect-[3/4] bg-muted overflow-hidden
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                color: AppTheme.mutedColor(context),
                                child: AspectRatio(
                                  aspectRatio: 3 / 4,
                                  child: hasProductImages
                                      ? PageView.builder(
                                          controller: _pageController,
                                          itemCount: images.length,
                                          onPageChanged: (i) =>
                                              setState(() => _imageIndex = i),
                                          itemBuilder: (context, i) =>
                                              CachedNetworkImage(
                                                imageUrl: safeImageUrl(images[i]),
                                                fit: BoxFit.cover,
                                                placeholder: (_, __) => Container(
                                                  color: AppTheme.mutedColor(context),
                                                  child: const Center(
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                ),
                                                errorWidget: (_, __, ___) => Container(
                                                  color: AppTheme.mutedColor(context),
                                                  child: const Icon(Icons.image_not_supported, size: 64),
                                                ),
                                              ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.image_outlined,
                                            size: 64,
                                            color: AppTheme.foregroundColor(context).withValues(alpha: 0.35),
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
                                          context.read<WishlistBloc>().add(
                                            WishlistRemoveItemRequested(
                                              product.id,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Removed from wishlist',
                                              ),
                                            ),
                                          );
                                        } else {
                                          context.read<WishlistBloc>().add(
                                            WishlistAddItemRequested(
                                              product.id,
                                              productName: product.name,
                                              productImage: product.firstImage,
                                              productPrice: product.price,
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Added to wishlist',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(24),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Icon(
                                          isWishlisted
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 22,
                                          color: isWishlisted
                                              ? AppTheme.primaryColor(context)
                                              : AppTheme.foregroundColor(
                                                  context,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Image indicators (only when multiple product images)
                                if (hasProductImages && images.length > 1)
                                Positioned(
                                  bottom: 16,
                                  left: 0,
                                  right: 0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(
                                      images.length,
                                      (i) => GestureDetector(
                                        onTap: () {
                                          setState(() => _imageIndex = i);
                                          _pageController.animateToPage(i,
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 3,
                                          ),
                                          width: i == _imageIndex ? 24 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: i == _imageIndex
                                                ? Colors.white
                                                : Colors.white.withValues(
                                                    alpha: 0.5,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Rating badge: from approved reviews API (not product seed fields)
                                if (_showProductRatingUI())
                                  Positioned(
                                    bottom: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _ratingLabel(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.star,
                                            size: 14,
                                            color: AppTheme.primaryColor(
                                              context,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '|',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.5),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$_productReviewsTotal',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          if (hasProductImages)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: Colors.white,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: List.generate(
                                    images.length,
                                    (i) => Padding(
                                      padding: EdgeInsets.only(
                                        right: i < images.length - 1 ? 8 : 0,
                                      ),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() => _imageIndex = i);
                                          _pageController.animateToPage(i,
                                            duration: const Duration(milliseconds: 350),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: i == _imageIndex
                                                  ? AppTheme.primaryColor(
                                                      context,
                                                    )
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                          clipBehavior: Clip.antiAlias,
                                          child: CachedNetworkImage(
                                            imageUrl: safeImageUrl(images[i]),
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                              color: AppTheme.mutedColor(
                                                context,
                                              ),
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
                      ), // image gallery Column
                      // Product info (match React mobile: title, category, price, size, Buy Now + Add to Bag)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title & category
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (product.isGift) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                    child: Text(
                                      'GIFT',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              product.category,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.foregroundColor(
                                  context,
                                ).withValues(alpha: 0.6),
                              ),
                            ),
                            // Price row (match React: $price, strikethrough, % OFF badge)
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _formatPrice(context, product),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (product.originalPrice != null &&
                                    product.originalPrice! > product.price) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatOriginalPrice(context, product),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: AppTheme.foregroundColor(
                                        context,
                                      ).withValues(alpha: 0.4),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${(((product.originalPrice! - product.price) / product.originalPrice!) * 100).round()}% OFF',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor(context),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Text(
                                            'Garment Measurement: Chest 41.0in',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.foregroundColor(
                                                context,
                                              ).withValues(alpha: 0.6),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        _showSizeChartDialog(context),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text('Size Chart'),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 18,
                                          color: AppTheme.primaryColor(context),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_selectedSize == null &&
                                  product.sizes.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor(
                                        context,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Size ${product.sizes[product.sizes.length ~/ 2]} Recommended',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.primaryColor(context),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: product.sizes.map((size) {
                                  final selected = _selectedSize == size;
                                  final available = product.stock[size] ?? 0;
                                  final outOfStock = available == 0;
                                  final availabilityText = outOfStock
                                      ? 'Out of stock'
                                      : available <= 5
                                      ? '$available left'
                                      : 'In stock';
                                  final sizeColor = outOfStock
                                      ? AppTheme.foregroundColor(
                                          context,
                                        ).withValues(alpha: 0.4)
                                      : selected
                                      ? AppTheme.backgroundColor(context)
                                      : AppTheme.foregroundColor(context);
                                  final availabilityColor = outOfStock
                                      ? AppTheme.foregroundColor(
                                          context,
                                        ).withValues(alpha: 0.4)
                                      : selected
                                      ? AppTheme.backgroundColor(
                                          context,
                                        ).withValues(alpha: 0.9)
                                      : AppTheme.foregroundColor(
                                          context,
                                        ).withValues(alpha: 0.7);
                                  return Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: outOfStock
                                          ? null
                                          : () => setState(
                                              () => _selectedSize = size,
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6,
                                          horizontal: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: outOfStock
                                              ? AppTheme.foregroundColor(
                                                  context,
                                                ).withValues(alpha: 0.06)
                                              : selected
                                              ? AppTheme.foregroundColor(
                                                  context,
                                                )
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: outOfStock
                                                ? AppTheme.borderColor(context)
                                                : selected
                                                ? AppTheme.foregroundColor(
                                                    context,
                                                  )
                                                : AppTheme.borderColor(context),
                                            width: 2,
                                          ),
                                        ),
                                        child: Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '$size  ',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: sizeColor,
                                                ),
                                              ),
                                              TextSpan(
                                                text: availabilityText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w400,
                                                  color: availabilityColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                            // Buy Now + Add to Bag (match React)
                            const SizedBox(height: 24),
                            BlocBuilder<CartBloc, CartState>(
                              buildWhen: (a, b) {
                                if (a is CartLoaded && b is CartLoaded) {
                                  return a.cart != b.cart;
                                }
                                return a != b;
                              },
                              builder: (context, cartState) {
                                final inCart = cartState is CartLoaded &&
                                    cartState.cart.items.any(
                                      (i) => i.productId == product.id,
                                    );
                                return Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          if (product.sizes.isNotEmpty &&
                                              _selectedSize == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select a size',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          final size =
                                              _selectedSize ??
                                              (product.sizes.isNotEmpty
                                                  ? product.sizes.first
                                                  : _oneSizeFallback);
                                          context.read<CartBloc>().add(
                                            CartAddItemRequested(
                                              CartItemEntity(
                                                productId: product.id,
                                                productName: product.name,
                                                image: product.firstImage ?? '',
                                                price: product.price,
                                                priceInr: product.priceInr,
                                                size: size,
                                                quantity: _quantity,
                                              ),
                                            ),
                                          );
                                          context.push('/cart');
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.primaryColor(
                                            context,
                                          ),
                                          side: BorderSide(
                                            color: AppTheme.primaryColor(
                                              context,
                                            ),
                                            width: 2,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 18,
                                            ),
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
                                          if (inCart) {
                                            context.push('/cart');
                                            return;
                                          }
                                          if (product.sizes.isNotEmpty &&
                                              _selectedSize == null) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Please select a size',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          final size =
                                              _selectedSize ??
                                              (product.sizes.isNotEmpty
                                                  ? product.sizes.first
                                                  : _oneSizeFallback);
                                          context.read<CartBloc>().add(
                                            CartAddItemRequested(
                                              CartItemEntity(
                                                productId: product.id,
                                                productName: product.name,
                                                image: product.firstImage ?? '',
                                                price: product.price,
                                                priceInr: product.priceInr,
                                                size: size,
                                                quantity: _quantity,
                                              ),
                                            ),
                                          );
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('Added to bag'),
                                            ),
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryColor(
                                            context,
                                          ),
                                          foregroundColor:
                                              AppTheme.primaryForegroundColor(
                                            context,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              inCart
                                                  ? Icons.shopping_bag
                                                  : Icons
                                                      .shopping_bag_outlined,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              inCart
                                                  ? 'Go to Bag'
                                                  : 'Add to Bag',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
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
                                color: AppTheme.foregroundColor(
                                  context,
                                ).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 18,
                                    color: AppTheme.foregroundColor(
                                      context,
                                    ).withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Select delivery address',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.primaryColor(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            _deliveryCard(
                              icon: Icons.local_shipping_outlined,
                              title: 'Delivery',
                              subtitle: DeliveryConstants.standardDeliveryDays,
                              isGreen: true,
                            ),
                            const SizedBox(height: 8),
                            _deliveryCard(
                              icon: Icons.payments_outlined,
                              title: 'Payment',
                              subtitle:
                                  'Options and any fees are shown at checkout.',
                              isGreen: true,
                            ),
                            const SizedBox(height: 8),
                            _deliveryCard(
                              icon: Icons.swap_horiz,
                              title: 'Returns',
                              subtitle: DeliveryConstants.returnInspectionDays,
                              isGreen: true,
                            ),
                            // Accordions: Description, Product Details, Customer Reviews (match React)
                            const SizedBox(height: 24),
                            _mobileAccordion(
                              'description',
                              'Description',
                              child: Text(
                                product.description.isEmpty
                                    ? 'No description available for this product.'
                                    : product.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.foregroundColor(
                                    context,
                                  ).withValues(alpha: 0.7),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            _mobileAccordion(
                              'details',
                              'Product Details',
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  top: 16,
                                  bottom: 16,
                                ),
                                child: Column(
                                  children: [
                                    _productDetailRow(
                                      'Material',
                                      product.material.isEmpty
                                          ? _emDash
                                          : product.material,
                                    ),
                                    const SizedBox(height: 12),
                                    _productDetailRow(
                                      'Care / details',
                                      _careFromProduct(product),
                                    ),
                                    const SizedBox(height: 12),
                                    _productDetailRow(
                                      'Country of origin',
                                      _emDash,
                                    ),
                                    const SizedBox(height: 12),
                                    _productDetailRow(
                                      'Product ID',
                                      product.id,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _mobileAccordion(
                              'reviews',
                              'Customer Reviews',
                              headerTrailing: _showProductRatingUI()
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 14,
                                          color: AppTheme.primaryColor(
                                            context,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _ratingLabel(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                              child: _buildProductReviewsBody(context, product.id),
                            ),
                            // API-driven "Frequently Bought Together" recommendations
                            if (_apiRecommendations.isNotEmpty)
                              _recommendationSection(
                                context,
                                title: 'Frequently Bought Together',
                                subtitle: 'Customers also purchased these',
                                icon: Icons.shopping_cart_outlined,
                                products: _apiRecommendations,
                              ),
                            // Recommendations (match React: You May Also Like, Similar, Trending, Complete the Look)
                            BlocBuilder<ProductListBloc, ProductListState>(
                              builder: (context, listState) {
                                if (listState is! ProductListLoaded)
                                  return const SizedBox(height: 80);
                                final all = listState.products;
                                final youMayAlsoLike = all
                                    .where(
                                      (p) =>
                                          p.id != product.id &&
                                          p.category == product.category,
                                    )
                                    .take(10)
                                    .toList();
                                final similar = all
                                    .where(
                                      (p) =>
                                          p.id != product.id &&
                                          p.category != product.category &&
                                          (p.price - product.price).abs() < 100,
                                    )
                                    .take(10)
                                    .toList();
                                final trending = all
                                    .where((p) {
                                      final relatedIds = youMayAlsoLike
                                          .map((e) => e.id)
                                          .toSet();
                                      return p.id != product.id &&
                                          (p.rating >= 4.5) &&
                                          !relatedIds.contains(p.id);
                                    })
                                    .take(10)
                                    .toList();
                                final completeLook = all
                                    .where(
                                      (p) =>
                                          p.id != product.id &&
                                          (p.price - product.price).abs() <
                                              50 &&
                                          p.category != product.category,
                                    )
                                    .take(3)
                                    .toList();
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _recommendationSection(
                                      context,
                                      title: 'You May Also Like',
                                      subtitle:
                                          'Handpicked recommendations just for you',
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
                                    _completeTheLookSection(
                                      context,
                                      product,
                                      completeLook,
                                    ),
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
          ),
        ],
        ),
      ),
    );
  }

  Widget _recommendationSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<ProductEntity> products,
    VoidCallback? onViewAll,
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
                        Icon(
                          icon,
                          size: 20,
                          color: AppTheme.primaryColor(context),
                        ),
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
                      onPressed:
                          onViewAll ?? () => context.push('/all-products'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppTheme.primaryColor(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.foregroundColor(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
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
                              AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.1),
                              AppTheme.primaryColor(
                                context,
                              ).withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor(
                              context,
                            ).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chevron_right,
                              size: 32,
                              color: AppTheme.primaryColor(context),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor(context),
                              ),
                            ),
                            Text(
                              '${products.length} products',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.foregroundColor(
                                  context,
                                ).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final p = products[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < products.length - 1 ? 12 : 0,
                  ),
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
                    color: AppTheme.mutedColor(context),
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
                  Icon(
                    Icons.star,
                    size: 12,
                    color: AppTheme.primaryColor(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${p.rating}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundColor(
                        context,
                      ).withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  CurrencyScope.of(context).formatPrice(p.price, p.priceInr),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
                if (p.originalPrice != null && p.originalPrice! > p.price) ...[
                  const SizedBox(width: 6),
                  Text(
                    CurrencyScope.of(
                      context,
                    ).formatPrice(p.originalPrice!, null),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foregroundColor(
                        context,
                      ).withValues(alpha: 0.4),
                      decoration: TextDecoration.lineThrough,
                    ),
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
                    Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: AppTheme.primaryColor(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Complete the Look',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Bundle and save 10% on your purchase',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.foregroundColor(
                      context,
                    ).withValues(alpha: 0.6),
                  ),
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
                    color: isMain
                        ? AppTheme.primaryColor(context).withValues(alpha: 0.3)
                        : AppTheme.borderColor(context),
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
                        color: isMain
                            ? AppTheme.primaryColor(context)
                            : Colors.white,
                        border: Border.all(
                          color: AppTheme.borderColor(context),
                        ),
                      ),
                      child: isMain
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
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
                            color: AppTheme.mutedColor(context),
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.foregroundColor(
                                context,
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyScope.of(
                              context,
                            ).formatPrice(p.price, p.priceInr),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isMain)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(
                            context,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'SELECTED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor(context),
                          ),
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
                border: Border.all(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal (${allProducts.length} items)',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.foregroundColor(
                            context,
                          ).withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        CurrencyScope.of(context).formatPrice(
                          allProducts.fold<double>(0, (s, p) => s + p.price),
                          null,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Bundle Discount (10%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _successGreen,
                        ),
                      ),
                      Text(
                        '-${CurrencyScope.of(context).formatPrice((allProducts.fold<double>(0, (s, p) => s + p.price) * _bundleDiscountRate), null)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _successGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: AppTheme.borderColor(context)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyScope.of(context).formatPrice(
                              (allProducts.fold<double>(
                                    0,
                                    (s, p) => s + p.price,
                                  ) *
                                  (1 - _bundleDiscountRate)),
                              null,
                            ),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor(context),
                            ),
                          ),
                          Text(
                            'You save ${CurrencyScope.of(context).formatPrice((allProducts.fold<double>(0, (s, p) => s + p.price) * _bundleDiscountRate), null)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _successGreen,
                            ),
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
                      onPressed: () {
                        final cartBloc = context.read<CartBloc>();
                        for (final p in allProducts) {
                          cartBloc.add(
                            CartAddItemRequested(
                              CartItemEntity(
                                productId: p.id,
                                productName: p.name,
                                image: p.firstImage ?? '',
                                price: p.price,
                                size: _oneSizeFallback,
                                quantity: 1,
                              ),
                            ),
                          );
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${allProducts.length} item(s) added to cart',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_bag, size: 20),
                      label: const Text('Add Bundle to Cart'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor(context),
                        foregroundColor: AppTheme.primaryForegroundColor(
                          context,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
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
                color: _successGreenBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '✨ ${DeliveryConstants.freeShippingPromoLine(CurrencyScope.of(context).region)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _successGreen,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Match React Product Details: flex justify-between text-sm, left foreground/60, right font-medium
  Widget _productDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

}
