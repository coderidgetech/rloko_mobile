import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/region/app_region.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/region/presentation/region_bloc.dart';

/// Settings (matches React MobileSettingsPage: Country/Region, Language, Change Password).
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'App preferences',
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 24),
          BlocBuilder<RegionBloc, RegionState>(
            builder: (context, state) {
              final region = state.region;
              return ListTile(
                leading: Icon(Icons.public, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
                title: const Text('Country / Region'),
                subtitle: Text(
                  '${region.displayName} • ${region.currencyCode}',
                  style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCountryPicker(context, region),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.lock_outline, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          ListTile(
            leading: Icon(Icons.language, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7)),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language'),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker(BuildContext context, AppRegion current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(ctx),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.foregroundColor(ctx).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Select Country / Region',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              _RegionOption(
                region: AppRegion.unitedStates,
                isSelected: current == AppRegion.unitedStates,
                onTap: () {
                  context.read<RegionBloc>().add(const RegionSetRequested(AppRegion.unitedStates));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Region changed to United States')),
                  );
                },
              ),
              _RegionOption(
                region: AppRegion.india,
                isSelected: current == AppRegion.india,
                onTap: () {
                  context.read<RegionBloc>().add(const RegionSetRequested(AppRegion.india));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Region changed to India')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegionOption extends StatelessWidget {
  const _RegionOption({
    required this.region,
    required this.isSelected,
    required this.onTap,
  });

  final AppRegion region;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.primaryColor(context).withValues(alpha: 0.1) : null,
      child: ListTile(
        leading: Text(region == AppRegion.india ? '🇮🇳' : '🇺🇸', style: const TextStyle(fontSize: 24)),
        title: Text(
          region.displayName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppTheme.primaryColor(context) : null,
          ),
        ),
        subtitle: Text(
          region.currencyCode,
          style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
        ),
        trailing: isSelected ? Icon(Icons.check, color: AppTheme.primaryColor(context)) : null,
        onTap: onTap,
      ),
    );
  }
}
