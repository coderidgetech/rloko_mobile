import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';

/// Horizontal scroll of category pills matching React QuickCategorySwitcher.
/// Women, Men, New, Sale, Dresses, Shoes, Jewelry, Bags, All. Active = primary bg.
class QuickCategorySwitcher extends StatelessWidget {
  const QuickCategorySwitcher({
    super.key,
    required this.gender,
    required this.slug,
  });

  final String gender;
  final String slug;

  static const List<({String id, String name, String emoji, String link, String? badge})> _categories = [
    (id: 'women', name: 'Women', emoji: '👗', link: '/category/women', badge: null),
    (id: 'men', name: 'Men', emoji: '👔', link: '/category/men', badge: null),
    (id: 'new', name: 'New', emoji: '✨', link: '/new-arrivals', badge: null),
    (id: 'sale', name: 'Sale', emoji: '🔥', link: '/sale', badge: null),
    (id: 'dresses', name: 'Dresses', emoji: '👠', link: '/category/women/dresses', badge: null),
    (id: 'shoes', name: 'Shoes', emoji: '👟', link: '/category/women/shoes', badge: null),
    (id: 'jewelry', name: 'Jewelry', emoji: '💎', link: '/category/women/jewelry', badge: null),
    (id: 'bags', name: 'Bags', emoji: '👜', link: '/category/women/clothing', badge: null),
    (id: 'all', name: 'All', emoji: '🛍️', link: '/all-products', badge: null),
  ];

  String _activeId() {
    if (gender == 'women' && slug.isEmpty) return 'women';
    if (gender == 'men' && slug.isEmpty) return 'men';
    if (slug == 'dresses') return 'dresses';
    if (slug == 'shoes') return 'shoes';
    if (slug == 'jewelry') return 'jewelry';
    if (slug == 'clothing' || slug == 'accessories') return 'bags';
    return 'all';
  }

  @override
  Widget build(BuildContext context) {
    final activeId = _activeId();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: _categories.map((cat) {
            final isActive = activeId == cat.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.safePush(cat.link),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryColor(context) : AppTheme.backgroundColor(context),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isActive ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                        width: 1,
                      ),
                      boxShadow: isActive ? [BoxShadow(color: AppTheme.primaryColor(context).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isActive ? AppTheme.primaryForegroundColor(context) : AppTheme.foregroundColor(context).withValues(alpha: 0.7),
                          ),
                        ),
                        if (cat.badge != null && !isActive) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor(context),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              cat.badge!,
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
