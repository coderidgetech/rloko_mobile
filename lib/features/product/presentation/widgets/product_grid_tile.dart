import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

/// Product card matching React MobileProductGrid pin-to-pin:
/// aspect 3/4 image, rounded-2xl (16px), wishlist top-right, SALE/NEW badges,
/// rating, name line-clamp-2, category, price (primary color).
class ProductGridTile extends StatelessWidget {
  const ProductGridTile({
    super.key,
    required this.product,
  });

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.firstImage;
    final wishlistState = context.watch<WishlistBloc>().state;
    final isInWishlist = wishlistState is WishlistLoaded &&
        wishlistState.items.any((i) => i.productId == product.id);

    return InkWell(
      onTap: () => context.push('/product/${product.id}'),
      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Image: aspect 3/4 (React)
            AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radius2xl),
                    ),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: safeImageUrl(imageUrl),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            placeholder: (_, __) => Container(
                              color: AppTheme.mutedColor(context),
                              child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.mutedColor(context),
                              child: const Icon(Icons.image_not_supported, size: 40),
                            ),
                          )
                        : Container(
                            color: AppTheme.mutedColor(context),
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),
                  // Wishlist: top-2 right-2, w-8 h-8, bg-white/90
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      elevation: 1,
                      child: InkWell(
                        onTap: () {
                          if (isInWishlist) {
                            context.read<WishlistBloc>().add(
                                WishlistRemoveItemRequested(product.id));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from wishlist')),
                            );
                          } else {
                            context.read<WishlistBloc>().add(
                                WishlistAddItemRequested(
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
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                            size: 16,
                            color: isInWishlist
                                ? AppTheme.primaryColor(context)
                                : AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // SALE badge: top-2 left-2, text-[10px] px-2 py-1 rounded-full
                  if (product.onSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // NEW badge (only if not on sale)
                  if (product.newArrival && !product.onSale)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.foregroundColor(context),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  // GIFT badge
                  if (product.isGift)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade700,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: const Text(
                          'GIFT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Product info: name, category, price — constrained so text fits and ellipsizes
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.rating > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 10, color: AppTheme.primaryColor(context)),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.foregroundColor(context).withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    Flexible(
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.foregroundColor(context),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (product.category.isNotEmpty)
                      Text(
                        product.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.foregroundColor(context).withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            CurrencyScope.of(context).formatPrice(product.price, product.priceInr),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.originalPrice != null &&
                            product.originalPrice! > product.price)
                          Text(
                            CurrencyScope.of(context).formatPrice(product.originalPrice!, null),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.foregroundColor(context).withValues(alpha: 0.4),
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
