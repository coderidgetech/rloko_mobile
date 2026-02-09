import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Language selection (mock UI to match React MobileLanguagePage).
/// Selection is stored in state; full app locale would require localization package.
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedLanguage = 'en';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
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
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: Icon(
              _selectedLanguage == 'en' ? Icons.check_circle : Icons.circle_outlined,
              color: _selectedLanguage == 'en' ? AppTheme.primaryColor(context) : AppTheme.mutedForegroundColor(context),
              size: 24,
            ),
            title: const Text('English'),
            onTap: () {
              setState(() => _selectedLanguage = 'en');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language set to English')),
              );
            },
          ),
          ListTile(
            leading: Icon(
              _selectedLanguage == 'hi' ? Icons.check_circle : Icons.circle_outlined,
              color: _selectedLanguage == 'hi' ? AppTheme.primaryColor(context) : AppTheme.mutedForegroundColor(context),
              size: 24,
            ),
            title: const Text('Hindi'),
            onTap: () {
              setState(() => _selectedLanguage = 'hi');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language set to Hindi')),
              );
            },
          ),
        ],
      ),
    );
  }
}
