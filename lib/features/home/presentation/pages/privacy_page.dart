import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Privacy Policy – full content page.
class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const _sections = [
    ('Information we collect', 'We collect information you provide (name, email, address, phone, payment details when you order), device information, and usage data (pages visited, actions taken) to operate and improve our service.'),
    ('How we use your information', 'We use your information to process orders, communicate about your account and deliveries, send promotional messages (with your consent), improve our app and website, prevent fraud, and comply with legal obligations.'),
    ('Cookies and similar technologies', 'We use cookies and similar technologies to remember preferences, analyze traffic, and personalize content. You can manage cookie settings in your browser or device.'),
    ('Sharing of information', 'We may share your information with payment processors, shipping partners, and service providers who assist our operations. We do not sell your personal information to third parties for their marketing.'),
    ('Data retention', 'We retain your data for as long as your account is active or as needed to provide services, comply with law, or resolve disputes. You may request deletion of your data subject to applicable law.'),
    ('Your rights', 'You may access, correct, or delete your personal information through your account settings or by contacting us. You may opt out of marketing communications at any time. In certain jurisdictions you have additional rights (e.g. data portability, objection).'),
    ('Security', 'We implement appropriate technical and organizational measures to protect your data. No method of transmission over the internet is 100% secure; we cannot guarantee absolute security.'),
    ('Children', 'Our service is not directed to individuals under 18. We do not knowingly collect personal information from children. If you believe we have collected such data, please contact us.'),
    ('Contact', 'For privacy-related questions or to exercise your rights, contact us at support@rloco.com or through the Contact Us page.'),
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
              'Privacy Policy',
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
