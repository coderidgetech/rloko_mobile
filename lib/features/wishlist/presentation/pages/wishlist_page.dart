import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/wishlist_entity.dart';
import '../bloc/wishlist_bloc.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../../cart/domain/entities/cart_item_entity.dart';
import '../../../cart/presentation/bloc/cart_bloc.dart';

/// Match React MobileWishlistPage: grid grid-cols-2 gap-3, card rounded-2xl border,
/// image aspect 3/4, Trash top-right, p-3 name/price, Add to Cart button rounded-full.
class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  bool _retriedAfterAuth = false;

  @override
  void initState() {
    super.initState();
    context.read<WishlistBloc>().add(const WishlistLoadRequested());
  }

  void _retryIfAuthenticated() {
    if (_retriedAfterAuth) return;
    final authState = context.read<AuthBloc>().state;
    final listState = context.read<WishlistBloc>().state;
    if (authState is AuthAuthenticated &&
        listState is WishlistError &&
        listState.message.contains('Sign in')) {
      _retriedAfterAuth = true;
      context.read<WishlistBloc>().add(const WishlistLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    // When opened from Account while logged in, retry if we're still showing 401
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _retryIfAuthenticated();
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocBuilder<WishlistBloc, WishlistState>(
        builder: (context, state) {
          if (state is WishlistLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is WishlistError) {
            return EmptyState(
              title: state.message.contains('Sign in')
                  ? 'Sign in to view wishlist'
                  : 'Could not load wishlist',
              subtitle: state.message,
              icon: Icons.favorite_border,
              actionLabel: state.message.contains('Sign in') ? 'Sign in' : 'Retry',
              onAction: () {
                if (state.message.contains('Sign in')) {
                  context.push('/login', extra: '/wishlist');
                } else {
                  context.read<WishlistBloc>().add(const WishlistLoadRequested());
                }
              },
            );
          }
          if (state is WishlistLoaded) {
            if (state.items.isEmpty) {
              return EmptyState(
                title: 'Your wishlist is empty',
                subtitle: 'Save your favorite items for later',
                icon: Icons.favorite_border,
                actionLabel: 'Explore Products',
                onAction: () => context.go('/'),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.56,
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return _WishlistCard(
                    item: item,
                    onTap: () => context.push('/product/${item.productId}'),
                    onRemove: () {
                      context.read<WishlistBloc>().add(
                          WishlistRemoveItemRequested(item.productId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from wishlist')),
                      );
                    },
                    onAddToCart: () {
                      final name = item.productName ?? 'Product';
                      final image = item.productImage ?? '';
                      final price = item.productPrice ?? 0.0;
                      context.read<CartBloc>().add(CartAddItemRequested(
                            CartItemEntity(
                              productId: item.productId,
                              productName: name,
                              image: image,
                              price: price,
                              size: 'One Size',
                              quantity: 1,
                            ),
                          ));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to cart!')),
                      );
                    },
                  );
                },
              ),
            );
          }
          return EmptyState(
            title: 'Your wishlist is empty',
            subtitle: 'Save your favorite items for later',
            icon: Icons.favorite_border,
            actionLabel: 'Explore Products',
            onAction: () => context.go('/'),
          );
        },
      ),
    );
  }
}

/// Single card: rounded-2xl border, aspect 3/4 image, Trash top-right, p-3 name + price + Add to Cart (match React)
class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
    required this.onAddToCart,
  });

  final WishlistEntity item;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final name = item.productName ?? 'Product';
    final image = item.productImage ?? '';
    final price = item.productPrice;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image aspect 3/4, tappable, with Trash top-right
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: image.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: safeImageUrl(image),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.mutedColor(context),
                            child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.mutedColor(context),
                            child: const Icon(Icons.image),
                          ),
                        )
                      : Container(
                          color: AppTheme.mutedColor(context),
                          child: const Icon(Icons.image, size: 48),
                        ),
                ),
                // Remove button: absolute top-2 right-2 w-8 h-8 rounded-full bg-white/90
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: onRemove,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.delete_outline,
                          size: 14,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product info: p-3 name, price, Add to Cart button
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (price != null)
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor(context),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: FilledButton.icon(
                    onPressed: onAddToCart,
                    icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                    label: const Text('Add to Cart'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor(context),
                      foregroundColor: AppTheme.primaryForegroundColor(context),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
