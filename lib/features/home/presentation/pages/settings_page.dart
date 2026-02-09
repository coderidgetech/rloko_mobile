import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Settings (mock UI to match React MobileSettingsPage).
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
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/change-password'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/language'),
          ),
        ],
      ),
    );
  }
}
