import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/locale/app_locale.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// English / Hindi — choice is persisted and drives [MaterialApp] locale.
class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  Future<void> _setLocale(
    BuildContext context,
    Locale locale,
  ) async {
    await setAppLocale(sl<SharedPreferences>(), locale);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            locale.languageCode == 'hi'
                ? 'भाषा हिन्दी पर सेट की गई'
                : 'Language set to English',
          ),
        ),
      );
    }
  }

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
          ListenableBuilder(
            listenable: appLocale,
            builder: (context, __) {
              final code = appLocale.value.languageCode;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      code == 'en' ? Icons.check_circle : Icons.circle_outlined,
                      color: code == 'en' ? AppTheme.primaryColor(context) : AppTheme.mutedForegroundColor(context),
                      size: 24,
                    ),
                    title: const Text('English'),
                    onTap: () => _setLocale(context, const Locale('en')),
                  ),
                  ListTile(
                    leading: Icon(
                      code == 'hi' ? Icons.check_circle : Icons.circle_outlined,
                      color: code == 'hi' ? AppTheme.primaryColor(context) : AppTheme.mutedForegroundColor(context),
                      size: 24,
                    ),
                    title: const Text('Hindi (हिन्दी)'),
                    onTap: () => _setLocale(context, const Locale('hi')),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
