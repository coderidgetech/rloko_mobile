import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

/// Product card matching React MobileProductGrid pin-to-pin:
/// aspect 3/4 image, rounded-2xl (16px), wishlist top-right, SALE/NEW badges,
/// rating, name line-clamp-2, category, price (primary color).
class ProductGridTile extends StatelessWidget {
  const ProductGridTile({super.key, required this.product});

  final ProductEntity product;

  // Design-system amber (Tailwind amber-700). Kept as a constant to avoid
  // runtime Color.shade allocations and to make it easy to update centrally.
  static const Color _giftBadgeColor = Color(0xFFB45309);
  // Tailwind red-600 — used for the discount-percentage badge.
  static const Color _discountBadgeColor = Color(0xFFDC2626);

  // Small rounded pill used for SALE / NEW / discount badges.
  Widget _badge(String text, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: AppTheme.fontSizeXs,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.firstImage;
    final original = product.originalPrice;
    final discountPct = (original != null && original > product.price && original > 0)
        ? (((original - product.price) / original) * 100).round()
        : 0;

    // context.select rebuilds this widget only when THIS product's wishlist
    // membership changes, not on every WishlistBloc emission.
    final isInWishlist = context.select<WishlistBloc, bool>((bloc) {
      final state = bloc.state;
      if (state is! WishlistLoaded) return false;
      return state.items.any((i) => i.productId == product.id);
    });

    return InkWell(
      onTap: () => context.safePush('/product/${product.id}'),
      borderRadius: BorderRadius.circular(AppTheme.radius2xl),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(AppTheme.radius2xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.max,
          children: [
            // Image: fill cell above text; [Expanded] + [inflexible] lets aspect ratio
            // shrink in short grid cells and avoids RenderFlex overflow.
            Expanded(
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppTheme.radius2xl),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Semantics(
                              label: product.name,
                              child: SafeCachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : Semantics(
                              label: '${product.name} - image unavailable',
                              child: Container(
                                color: AppTheme.mutedColor(context),
                                child: const Icon(Icons.image, size: 40),
                              ),
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
                                WishlistRemoveItemRequested(product.id),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Removed from wishlist'),
                                  ),
                                );
                              }
                            } else {
                              context.read<WishlistBloc>().add(
                                WishlistAddItemRequested(
                                  product.id,
                                  productName: product.name,
                                  productImage: product.firstImage,
                                  productPrice: product.price,
                                ),
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added to wishlist'),
                                  ),
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          // 40x40 keeps a comfortable touch target (the old 32px
                          // was below the recommended minimum and easy to miss).
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color: isInWishlist
                                  ? AppTheme.primaryColor(context)
                                  : AppTheme.foregroundColor(
                                      context,
                                    ).withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Top-left badge stack: SALE/NEW, then the discount percentage.
                    if (product.onSale || product.newArrival || discountPct > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.onSale)
                              _badge('SALE', AppTheme.primaryColor(context))
                            else if (product.newArrival)
                              _badge('NEW', AppTheme.foregroundColor(context)),
                            if (discountPct > 0) ...[
                              if (product.onSale || product.newArrival)
                                const SizedBox(height: 4),
                              _badge('-$discountPct%', _discountBadgeColor),
                            ],
                          ],
                        ),
                      ),
                    // GIFT badge
                    if (product.isGift)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _giftBadgeColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusFull,
                            ),
                          ),
                          child: const Text(
                            'GIFT',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeXs,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // OUT OF STOCK overlay
                    if (product.stock.isNotEmpty &&
                        product.stock.values.every((q) => q <= 0)) ...[
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(AppTheme.radius2xl),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: const Text(
                              'Out of stock',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeXs,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Non-flex block: [Expanded] image above gets the remaining height after this.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.rating > 0) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 10,
                          color: AppTheme.primaryColor(context),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          product.rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeXs,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.foregroundColor(
                              context,
                            ).withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
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
                  const SizedBox(height: 2),
                  if (product.category.isNotEmpty)
                    Text(
                      product.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXs,
                        color: AppTheme.foregroundColor(
                          context,
                        ).withValues(alpha: 0.5),
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
                          CurrencyScope.of(
                            context,
                          ).formatPrice(product.price, product.priceInr),
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSm,
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
                          CurrencyScope.of(
                            context,
                          ).formatPrice(product.originalPrice!, null),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.foregroundColor(
                              context,
                            ).withValues(alpha: 0.4),
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
          ],
        ),
      ),
    );
  }
}
