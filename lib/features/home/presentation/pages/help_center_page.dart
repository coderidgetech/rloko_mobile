import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Help Center with FAQ, track order, and support links.
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  static const _faqs = [
    ('How do I track my order?', 'Go to Account → My Orders, open your order and use the tracking link. You can also check your email for shipping updates.'),
    ('What is your return policy?', 'We offer 30-day hassle-free returns. Items must be unused with original tags. Go to Account → Returns & Refunds to start a return.'),
    ('How can I change or cancel my order?', 'If your order has not shipped, contact us immediately via Contact Us. Once shipped, you can return it after delivery.'),
    ('What payment methods do you accept?', 'We accept credit/debit cards, UPI, net banking, and wallet payments. You can save payment methods in Account → Payment Methods.'),
    ('How do I use a coupon?', 'Add items to cart, go to checkout, and enter your coupon code in the promo field. Tap Apply to see the discount.'),
    ('Do you ship internationally?', 'We currently ship across India. International shipping is available to select countries; check Shipping Info for details.'),
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
              'Help Center',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Find answers and get support',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              icon: Icons.inventory_2_outlined,
              title: 'Track your order',
              subtitle: 'View status and tracking for your orders.',
              actionLabel: 'My Orders',
              onTap: () => context.push('/orders'),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.replay_outlined,
              title: 'Returns & Refunds',
              subtitle: 'Start a return or check refund status.',
              actionLabel: 'Returns',
              onTap: () => context.push('/returns'),
            ),
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Shipping information',
              subtitle: 'Delivery times, costs, and coverage.',
              actionLabel: 'Shipping Info',
              onTap: () => context.push('/shipping'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Frequently asked questions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ..._faqs.map((q) => _FaqTile(question: q.$1, answer: q.$2)),
            const SizedBox(height: 24),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/contact'),
                icon: const Icon(Icons.mail_outline, size: 20),
                label: const Text('Contact support'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.backgroundColor(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor(context)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primaryColor(context), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                    ),
                  ],
                ),
              ),
              Text(
                actionLabel,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primaryColor(context)),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: AppTheme.mutedForegroundColor(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.foregroundColor(context).withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              answer,
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
