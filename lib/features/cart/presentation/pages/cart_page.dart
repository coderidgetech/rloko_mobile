import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/form_hints.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../bloc/cart_bloc.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';

/// Mock coupon codes (match React COUPON_CODES)
const _couponCodes = {'RLOCO10': 10, 'SAVE20': 20, 'WELCOME15': 15};

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _couponController = TextEditingController();
  String? _appliedCouponCode;
  int? _appliedCouponDiscount;
  bool _showCouponInput = false;

  @override
  void initState() {
    super.initState();
    context.read<CartBloc>().add(const CartLoadRequested());
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    final discount = _couponCodes[code];
    if (discount != null) {
      setState(() {
        _appliedCouponCode = code;
        _appliedCouponDiscount = discount;
        _showCouponInput = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coupon $code applied! $discount% off')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid coupon code')),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _appliedCouponDiscount = null;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coupon removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: false),
      bottomNavigationBar: const _BottomNav(currentIndex: 4),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (state is CartError) {
            final isUnauth = state.message.contains('Sign in');
            return EmptyState(
              title: isUnauth ? 'Sign in to view cart' : 'Could not load cart',
              subtitle: state.message,
              icon: Icons.shopping_bag_outlined,
              actionLabel: isUnauth ? 'Sign in' : 'Retry',
              onAction: () {
                if (isUnauth) {
                  context.push('/login', extra: '/cart');
                } else {
                  context.read<CartBloc>().add(const CartLoadRequested());
                }
              },
            );
          }
          if (state is CartLoaded) {
            if (state.cart.items.isEmpty) {
              return EmptyState(
                title: 'Your cart is empty',
                subtitle: 'Start shopping and add items to your cart',
                icon: Icons.shopping_bag_outlined,
                actionLabel: 'Start Shopping',
                onAction: () => context.go('/'),
              );
            }
            return _CartContent(
              items: state.cart.items,
              appliedCouponCode: _appliedCouponCode,
              appliedCouponDiscount: _appliedCouponDiscount,
              showCouponInput: _showCouponInput,
              couponController: _couponController,
              onShowCouponInput: () => setState(() => _showCouponInput = true),
              onApplyCoupon: _applyCoupon,
              onRemoveCoupon: _removeCoupon,
            );
          }
          return EmptyState(
            title: 'Your cart is empty',
            icon: Icons.shopping_bag_outlined,
            actionLabel: 'Start Shopping',
            onAction: () => context.go('/'),
          );
        },
      ),
    );
  }
}

class _CartContent extends StatelessWidget {
  const _CartContent({
    required this.items,
    required this.appliedCouponCode,
    required this.appliedCouponDiscount,
    required this.showCouponInput,
    required this.couponController,
    required this.onShowCouponInput,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  final List<CartItemEntity> items;
  final String? appliedCouponCode;
  final int? appliedCouponDiscount;
  final bool showCouponInput;
  final TextEditingController couponController;
  final VoidCallback onShowCouponInput;
  final VoidCallback onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  double get _subtotal =>
      items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  double get _discount =>
      appliedCouponDiscount != null
          ? (_subtotal * appliedCouponDiscount!) / 100
          : 0;
  double get _total => _subtotal - _discount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scrollable list (match React: pt padding, px-4, items with border-b)
        CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = items[index];
                    return _CartItemTile(
                      item: item,
                      onMoveToWishlist: () {
                        context.read<CartBloc>().add(
                            CartRemoveItemRequested(item.productId, item.size));
                        context.read<WishlistBloc>().add(WishlistAddItemRequested(
                              item.productId,
                              productName: item.productName,
                              productImage: item.image,
                              productPrice: item.price,
                            ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Moved to wishlist')),
                        );
                      },
                    );
                  },
                  childCount: items.length,
                ),
              ),
            ),
            // Coupon section (match React)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: AppTheme.foreground.withValues(alpha: 0.12)),
                  ),
                ),
                child: appliedCouponCode != null
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer,
                                size: 16, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$appliedCouponCode Applied (${appliedCouponDiscount}% off)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onRemoveCoupon,
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red.shade600),
                              ),
                            ),
                          ],
                        ),
                      )
                    : showCouponInput
                        ? Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: couponController,
                                  decoration: InputDecoration(
                                    hintText: FormHints.promoCode,
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  onSubmitted: (_) => onApplyCoupon(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: onApplyCoupon,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Apply'),
                              ),
                            ],
                          )
                        : InkWell(
                            onTap: onShowCouponInput,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AppTheme.foreground.withValues(alpha: 0.2),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.local_offer,
                                      size: 18,
                                      color: AppTheme.foreground
                                          .withValues(alpha: 0.6)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Apply Coupon',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.foreground,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.arrow_forward_ios,
                                      size: 18,
                                      color: AppTheme.foreground
                                          .withValues(alpha: 0.4)),
                                ],
                              ),
                            ),
                          ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 200),
            ),
          ],
        ),
        // Fixed bottom summary (match React)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.paddingOf(context).bottom),
            decoration: BoxDecoration(
              color: AppTheme.background,
              border: Border(
                top: BorderSide(
                    color: AppTheme.foreground.withValues(alpha: 0.12)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.foreground.withValues(alpha: 0.6)),
                      ),
                      Text(
                        '\$${_subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  if (_discount > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16A34A)),
                        ),
                        Text(
                          '-\$${_discount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Divider(color: AppTheme.foreground.withValues(alpha: 0.12)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => context.push('/checkout'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.primaryForeground,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)),
                        elevation: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Proceed to Checkout'),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Single cart row: image w-24 h-32 rounded-xl, name, size, price, quantity +/- , Heart, Trash (match React: py-4 border-b border-border/30)
class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onMoveToWishlist,
  });

  final CartItemEntity item;
  final VoidCallback onMoveToWishlist;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: AppTheme.foreground.withValues(alpha: 0.12)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image w-24 h-32 = 96x128, rounded-xl
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 96,
              height: 128,
              child: item.image.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: safeImageUrl(item.image),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          color: AppTheme.muted,
                          child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2))),
                      errorWidget: (_, __, ___) => Container(
                          color: AppTheme.muted,
                          child: const Icon(Icons.image)),
                    )
                  : Container(
                      color: AppTheme.muted,
                      child: const Icon(Icons.image),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.foreground.withValues(alpha: 0.5)),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Quantity: minus, count, plus (rounded-full buttons)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          shape: const CircleBorder(),
                          side: BorderSide(color: AppTheme.border),
                        ),
                        onPressed: item.quantity > 1
                            ? () => context.read<CartBloc>().add(
                                CartUpdateItemRequested(
                                    item.productId, item.size, item.quantity - 1))
                            : null,
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          shape: const CircleBorder(),
                          side: BorderSide(color: AppTheme.border),
                        ),
                        onPressed: () => context.read<CartBloc>().add(
                            CartUpdateItemRequested(
                                item.productId, item.size, item.quantity + 1)),
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ),
                    const Spacer(),
                    // Move to wishlist (Heart) and Remove (Trash)
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Material(
                        color: AppTheme.foreground.withValues(alpha: 0.05),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: onMoveToWishlist,
                          customBorder: const CircleBorder(),
                          child: Center(
                              child: Icon(Icons.favorite_border,
                                  size: 14,
                                  color: AppTheme.foreground.withValues(alpha: 0.6))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Material(
                        color: const Color(0xFFFEF2F2),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () {
                            context.read<CartBloc>().add(
                                CartRemoveItemRequested(item.productId, item.size));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Removed from cart')),
                            );
                          },
                          customBorder: const CircleBorder(),
                          child: const Center(
                              child: Icon(Icons.delete_outline,
                                  size: 14, color: Color(0xFFEF4444))),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex});
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.mutedForeground,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Cart'),
      ],
      onTap: (i) {
        if (i == 0) context.go('/');
        if (i == 1) context.go('/categories');
        if (i == 2) context.go('/search');
        if (i == 3) context.go('/account');
        if (i == 4) context.go('/cart');
      },
    );
  }
}
