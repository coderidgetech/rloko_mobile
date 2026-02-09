import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Language selection (mock UI to match React MobileLanguagePage).
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your preferred language',
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.check_circle, color: AppTheme.primary),
            title: const Text('English'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.circle_outlined, size: 24, color: AppTheme.mutedForeground),
            title: const Text('Hindi'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
