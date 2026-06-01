import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../theme/app_theme.dart';
// go_router is intentionally not imported here — navigation is handled by the
// _AppShell in app_router.dart via StatefulNavigationShell.goBranch.
import '../../features/cart/presentation/bloc/cart_bloc.dart';

/// Bottom navigation matching React Mobile: h-16 (64px), icons 22px, labels 10px,
/// active = primary + scale 110% + top indicator line (w-8 h-0.5), safe area bottom.
///
/// [currentIndex] is driven by [StatefulNavigationShell.currentIndex].
/// [onTap] calls [StatefulNavigationShell.goBranch] so each branch preserves
/// its own navigator stack when switching tabs.
class BottomNav extends StatelessWidget {
  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

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
        boxShadow: [BoxShadow(color: AppTheme.foregroundColor(context).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2))],
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
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Categories',
                isActive: currentIndex == 1,
                primary: primary,
                unselected: unselected,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                isActive: currentIndex == 2,
                primary: primary,
                unselected: unselected,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                label: 'Account',
                isActive: currentIndex == 3,
                primary: primary,
                unselected: unselected,
                onTap: () => onTap(3),
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
                    onTap: () => onTap(4),
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
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Semantics(
          label: '$label, tab',
          button: true,
          selected: isActive,
          child: Column(
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
              Badge(
                label: Text(
                  badgeCount > 9 ? '9+' : '$badgeCount',
                  style: const TextStyle(fontSize: 10),
                ),
                isLabelVisible: badgeCount > 0,
                child: Icon(
                  icon,
                  size: BottomNav._iconSize,
                  color: isActive ? primary : unselected,
                ),
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
        ),
      ),
    );
  }
}
