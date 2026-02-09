import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/config/presentation/bloc/config_bloc.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';

/// Common header matching React MobileSubPageHeader: Logo, Search, Wishlist (fav), Cart.
/// Optional back button. Used on the five main pages (Home, Categories, Search, Account, Cart).
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
  });

  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTheme.backgroundColor(context),
      foregroundColor: AppTheme.foregroundColor(context),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: onBack ?? () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            )
          : null,
      leadingWidth: showBackButton ? 48 : null,
      title: BlocBuilder<ConfigBloc, ConfigState>(
        buildWhen: (a, b) => b is ConfigLoaded,
        builder: (context, state) {
          final siteName = state is ConfigLoaded ? state.config.general.siteName : 'Rloco';
          return GestureDetector(
            onTap: () => context.go('/'),
            behavior: HitTestBehavior.opaque,
            child: Text(
              siteName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.foregroundColor(context),
              ),
            ),
          );
        },
      ),
      titleSpacing: showBackButton ? 0 : 16,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 24),
          onPressed: () => context.push('/search'),
          style: IconButton.styleFrom(
            foregroundColor: AppTheme.foregroundColor(context).withValues(alpha: 0.8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        BlocBuilder<WishlistBloc, WishlistState>(
          builder: (context, state) {
            final count = state is WishlistLoaded ? state.count : 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 24),
                  onPressed: () => context.push('/wishlist'),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.foregroundColor(context).withValues(alpha: 0.8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.destructive,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.backgroundColor(context), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        BlocBuilder<CartBloc, CartState>(
          builder: (context, state) {
            final count = state is CartLoaded ? state.cart.itemCount : 0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 24),
                  onPressed: () => context.push('/cart'),
                  style: IconButton.styleFrom(
                    foregroundColor: AppTheme.foregroundColor(context).withValues(alpha: 0.8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(
                        color: AppTheme.destructive,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.backgroundColor(context), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
