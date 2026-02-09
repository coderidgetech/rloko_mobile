import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Rewards / loyalty points (mock UI to match React MobileRewardsPage).
class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Rloco Rewards',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Earn points on every order',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    '450',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Points',
                    style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Shop to earn more points. Use points for discounts at checkout.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
