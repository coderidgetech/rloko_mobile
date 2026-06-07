import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// About Rloko – brand story and info.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About Rloko',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Curated fashion and lifestyle for everyone.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 24),
            Text(
              'Rloko is your destination for curated fashion and lifestyle products. We bring you quality apparel, accessories, and home goods from trusted brands and emerging labels—all in one place, with easy ordering and hassle-free returns.',
              style: TextStyle(fontSize: 15, color: AppTheme.foregroundColor(context), height: 1.5),
            ),
            const SizedBox(height: 20),
            const Text(
              'What we offer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _Bullet(context, 'Wide range of categories: clothing, footwear, bags, and more'),
            _Bullet(context, 'Secure payment and multiple options'),
            _Bullet(context, 'Fast delivery across India'),
            _Bullet(context, '30-day returns and dedicated support'),
            _Bullet(context, 'Rewards and coupons for loyal customers'),
            const SizedBox(height: 20),
            const Text(
              'Our commitment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'We are committed to quality, authenticity, and customer satisfaction. If you have feedback or questions, reach out via Contact Us—we\'d love to hear from you.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _Bullet(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: TextStyle(fontSize: 14, color: AppTheme.primaryColor(context), fontWeight: FontWeight.bold)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.4),
          ),
        ),
      ],
    ),
  );
}
