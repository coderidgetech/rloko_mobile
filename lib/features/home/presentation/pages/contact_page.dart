import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/presentation/bloc/config_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Contact Us – email, phone, hours; copy actions (values from site config when loaded).
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConfigBloc, ConfigState>(
      builder: (context, state) {
        final g = state is ConfigLoaded ? state.config.general : null;
        final email = (g?.supportEmail.isNotEmpty == true) ? g!.supportEmail : (g?.email ?? '');
        final phone = g?.phone ?? '';
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
            if (email.isNotEmpty) ...[
              _ContactCard(
                icon: Icons.mail_outline,
                title: 'Email',
                value: email,
                onCopy: () => _copyAndSnack(context, email, 'Email copied'),
              ),
              const SizedBox(height: 12),
            ],
            if (phone.isNotEmpty) ...[
              _ContactCard(
                icon: Icons.phone_outlined,
                title: 'Phone',
                value: phone,
                onCopy: () => _copyAndSnack(context, phone, 'Phone number copied'),
              ),
            ],
            if (email.isEmpty && phone.isEmpty) ...[
              Text(
                'Add contact details in the admin site settings to show them here.',
                style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context), height: 1.5),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Support hours',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Hours and holidays are announced in the app or in your order emails.',
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
      },
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
