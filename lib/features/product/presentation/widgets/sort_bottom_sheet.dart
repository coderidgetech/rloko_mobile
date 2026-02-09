import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Sort option shown in the bottom sheet.
class SortOption {
  const SortOption({required this.value, required this.label});
  final String value;
  final String label;
}

/// Modal bottom sheet for sort options (matches React mobile Sort By bottom sheet).
Future<String?> showSortBottomSheet(
  BuildContext context, {
  required List<SortOption> options,
  required String selectedValue,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => _SortBottomSheet(
      options: options,
      selectedValue: selectedValue,
    ),
  );
}

class _SortBottomSheet extends StatelessWidget {
  const _SortBottomSheet({
    required this.options,
    required this.selectedValue,
  });

  final List<SortOption> options;
  final String selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radius3xl)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sort By',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foregroundColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
            ),
            ...options.map((opt) {
              final isSelected = opt.value == selectedValue;
              return InkWell(
                onTap: () => Navigator.of(context).pop(opt.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      color: isSelected ? AppTheme.primaryColor(context) : AppTheme.foregroundColor(context),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
