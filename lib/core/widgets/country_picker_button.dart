import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../models/country.dart';

/// Button that opens a bottom sheet to pick country (matches React mobile country dropdown).
class CountryPickerButton extends StatelessWidget {
  const CountryPickerButton({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final Country selected;
  final ValueChanged<Country> onSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.foreground.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _showPicker(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 54,
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.border.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(selected.flag, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                selected.dialCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: AppTheme.foreground.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerSheet(
        selected: selected,
        onSelected: (c) {
          onSelected(c);
          Navigator.of(ctx).pop();
        },
      ),
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.selected,
    required this.onSelected,
  });

  final Country selected;
  final ValueChanged<Country> onSelected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  late TextEditingController _searchController;
  late List<Country> _filtered;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filtered = List.from(Country.all);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = List.from(Country.all);
      } else {
        final q = query.toLowerCase();
        _filtered = Country.all
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.dialCode.contains(query) ||
                c.code.toLowerCase().contains(q))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.foreground.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filter,
                  decoration: InputDecoration(
                    hintText: 'Search country...',
                    prefixIcon: Icon(
                      Icons.search,
                      size: 20,
                      color: AppTheme.foreground.withValues(alpha: 0.4),
                    ),
                    filled: true,
                    fillColor: AppTheme.muted.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppTheme.border.withValues(alpha: 0.3),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _filtered.length,
                  itemBuilder: (context, index) {
                    final c = _filtered[index];
                    final isSelected = c.code == widget.selected.code;
                    return Material(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        leading: Text(c.flag, style: const TextStyle(fontSize: 24)),
                        title: Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          c.code,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.foreground.withValues(alpha: 0.5),
                          ),
                        ),
                        trailing: Text(
                          c.dialCode,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.foreground.withValues(alpha: 0.7),
                          ),
                        ),
                        onTap: () => widget.onSelected(c),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
