import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Notifications list (mock UI to match React).
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none, size: 64, color: AppTheme.mutedForeground),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: TextStyle(fontSize: 18, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
