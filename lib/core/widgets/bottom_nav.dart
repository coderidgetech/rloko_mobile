import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

/// Bottom navigation matching React Mobile: h-16 (64px), icons 22px, labels 10px,
/// active = primary + scale 110% + top indicator line (w-8 h-0.5), safe area bottom.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const double _iconSize = 22;
  static const double _labelFontSize = 10;
  static const double _navHeight = 64;
  static const double _activeIndicatorWidth = 32;
  static const double _activeIndicatorHeight = 2;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final unselected = AppTheme.foregroundColor(context).withValues(alpha: 0.6);
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(top: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _navHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: currentIndex == 0,
                primary: primary,
                unselected: unselected,
                onTap: () => context.go('/'),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                isActive: currentIndex == 1,
                primary: primary,
                unselected: unselected,
                onTap: () => context.go('/categories'),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isActive: currentIndex == 2,
                primary: primary,
                unselected: unselected,
                onTap: () => context.go('/search'),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Account',
                isActive: currentIndex == 3,
                primary: primary,
                unselected: unselected,
                onTap: () => context.go('/account'),
              ),
              BlocBuilder<CartBloc, CartState>(
                builder: (context, cartState) {
                  final count = cartState is CartLoaded ? cartState.cart.itemCount : 0;
                  return _NavItem(
                    icon: Icons.shopping_bag_rounded,
                    label: 'Cart',
                    isActive: currentIndex == 4,
                    primary: primary,
                    unselected: unselected,
                    onTap: () => context.go('/cart'),
                    badgeCount: count,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.primary,
    required this.unselected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final Color primary;
  final Color unselected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isActive)
                  Container(
                    width: BottomNav._activeIndicatorWidth,
                    height: BottomNav._activeIndicatorHeight,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                Icon(
                  icon,
                  size: BottomNav._iconSize,
                  color: isActive ? primary : unselected,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: BottomNav._labelFontSize,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                    color: isActive ? primary : unselected,
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 10,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
