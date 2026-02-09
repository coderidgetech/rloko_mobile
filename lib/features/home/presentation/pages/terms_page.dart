import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Terms of Service – full content page.
class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const _sections = [
    ('Acceptance of terms', 'By accessing or using Rloco\'s website and mobile app, you agree to be bound by these Terms of Service. If you do not agree, please do not use our services.'),
    ('Use of service', 'You must use our platform only for lawful purposes. You may not misuse the service, attempt to gain unauthorized access, or use it in any way that could harm Rloco or other users.'),
    ('Account and orders', 'You are responsible for keeping your account credentials secure. Orders placed through your account are your responsibility. We reserve the right to refuse or cancel orders in case of errors, fraud, or policy violations.'),
    ('Products and pricing', 'We strive to display accurate product information and prices. We may correct errors and reserve the right to modify prices. If a product is mispriced, we may cancel the order and notify you.'),
    ('Shipping and delivery', 'Delivery times are estimates. We are not liable for delays caused by carriers or events beyond our control. Risk of loss passes to you upon delivery to the carrier.'),
    ('Returns and refunds', 'Our return policy is described in the Returns & Refunds section of the app. Refunds are processed to the original payment method within the stated timeframe after we receive and inspect the return.'),
    ('Intellectual property', 'All content on Rloco—including logos, text, images, and software—is owned by Rloco or its licensors and is protected by copyright and other laws. You may not copy or use it without permission.'),
    ('Disclaimer', 'Products are provided "as is." We disclaim warranties to the extent permitted by law. We are not liable for indirect, incidental, or consequential damages arising from your use of the service.'),
    ('Governing law', 'These terms are governed by the laws of India. Any disputes shall be subject to the exclusive jurisdiction of the courts in India.'),
    ('Changes', 'We may update these terms from time to time. Continued use of the service after changes constitutes acceptance. We encourage you to review this page periodically.'),
  ];

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
              'Terms of Service',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: January 2025',
              style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 24),
            ..._sections.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.$1,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.$2,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForegroundColor(context),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
