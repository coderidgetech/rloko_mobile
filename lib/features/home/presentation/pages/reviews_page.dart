import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// My reviews (placeholder to match React MobileReviewsPage).
class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star_border, size: 64, color: AppTheme.mutedForegroundColor(context)),
              const SizedBox(height: 16),
              Text(
                'No reviews yet',
                style: TextStyle(fontSize: 18, color: AppTheme.mutedForegroundColor(context)),
              ),
              const SizedBox(height: 8),
              Text(
                'Reviews you write for orders will appear here.',
                style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
