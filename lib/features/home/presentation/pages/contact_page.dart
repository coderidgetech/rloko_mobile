import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Contact Us – email, phone, hours; copy actions.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const _email = 'support@rloco.com';
  static const _phone = '+91 1800-123-4567';

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
              'Contact Us',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'We typically respond within 24 hours.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
            ),
            const SizedBox(height: 24),
            _ContactCard(
              icon: Icons.mail_outline,
              title: 'Email',
              value: _email,
              onCopy: () => _copyAndSnack(context, _email, 'Email copied'),
            ),
            const SizedBox(height: 12),
            _ContactCard(
              icon: Icons.phone_outlined,
              title: 'Phone',
              value: _phone,
              onCopy: () => _copyAndSnack(context, _phone, 'Phone number copied'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Support hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Mon–Sat: 9:00 AM – 6:00 PM IST\nClosed on public holidays.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'For returns',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a return from Account → Returns & Refunds. For help with an existing return, reply to the return confirmation email or contact us above.',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAndSnack(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onCopy,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Text(title, style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context))),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Copy'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
