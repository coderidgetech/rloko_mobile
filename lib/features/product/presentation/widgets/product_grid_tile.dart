import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/product_entity.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

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
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: safeImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => Container(
                            color: AppTheme.muted,
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.muted,
                            child: const Icon(Icons.image_not_supported, size: 40),
                          ),
                        )
                      : Container(
                          color: AppTheme.muted,
                          child: const Icon(Icons.image, size: 40),
                        ),
                ),
                // Wishlist button (match React: top-2 right-2, rounded-full bg-white/90)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
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
                              ? AppTheme.primary
                              : AppTheme.foreground.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '\$${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.foreground,
                ),
              ),
              if (product.originalPrice != null &&
                  product.originalPrice! > product.price) ...[
                const SizedBox(width: 8),
                Text(
                  '\$${product.originalPrice!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
