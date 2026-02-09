import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Bottom navigation bar (Home, Categories, Search, Account, Cart).
/// Used on main screens and category page.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.primaryColor(context),
      unselectedItemColor: AppTheme.mutedForegroundColor(context),
      selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: const TextStyle(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Categories'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Cart'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/categories');
            break;
          case 2:
            context.go('/search');
            break;
          case 3:
            context.go('/account');
            break;
          case 4:
            context.go('/cart');
            break;
        }
      },
    );
  }
}
