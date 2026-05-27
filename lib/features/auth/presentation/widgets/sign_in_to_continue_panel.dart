import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

/// Same pattern as [AccountPage] guest: icon, copy, **Sign in** (push, not go), optional Create account.
class SignInToContinuePanel extends StatelessWidget {
  const SignInToContinuePanel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.returnPath,
    this.icon = Icons.location_on_outlined,
    this.showCreateAccount = true,
  });

  final String title;
  final String subtitle;
  /// Pass to login as [LoginPage.redirectAfterLogin] (e.g. `/addresses` or `/addresses/add`).
  final String returnPath;
  final IconData icon;
  final bool showCreateAccount;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppTheme.primaryColor(context)),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: FilledButton(
                onPressed: () => context.push('/login', extra: returnPath),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                ),
                child: const Text('Sign in'),
              ),
            ),
          ),
          if (showCreateAccount) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: OutlinedButton(
                  onPressed: () => context.push('/signup'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                  ),
                  child: const Text('Create account'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
