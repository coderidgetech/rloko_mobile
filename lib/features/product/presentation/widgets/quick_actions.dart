import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Floating Filter + Sort buttons (matches React QuickActions).
class QuickActions extends StatelessWidget {
  const QuickActions({
    super.key,
    this.onFilterTap,
    this.onSortTap,
  });

  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: Row(
        children: [
          if (onFilterTap != null)
            Expanded(
              child: _ActionButton(
                icon: Icons.tune,
                label: 'Filter',
                onTap: onFilterTap!,
              ),
            ),
          if (onFilterTap != null && onSortTap != null) const SizedBox(width: 12),
          if (onSortTap != null)
            Expanded(
              child: _ActionButton(
                icon: Icons.sort,
                label: 'Sort',
                onTap: onSortTap!,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor(context),
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: AppTheme.foregroundColor(context)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foregroundColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
