import 'package:flutter/material.dart';

import '../constants/stripe_constants.dart';
import '../theme/app_theme.dart';

/// Labels aligned with web [CheckoutPage] (`card` | `upi` | `cod`).
String paymentMethodLabel(String id) {
  switch (id) {
    case 'cod':
      return 'Cash on Delivery';
    case 'card':
      return 'Credit / Debit Card';
    case 'upi':
      return 'UPI';
    default:
      return id;
  }
}

String? paymentMethodDetailLine(String id) {
  switch (id) {
    case 'cod':
      return 'Pay when you receive your order';
    case 'card':
      return 'Pay securely via Stripe';
    case 'upi':
      return 'UPI via Stripe (India)';
    default:
      return null;
  }
}

IconData paymentMethodLeadingIcon(String id) {
  switch (id) {
    case 'cod':
      return Icons.money_outlined;
    case 'upi':
      return Icons.phone_android_outlined;
    case 'card':
    default:
      return Icons.credit_card_outlined;
  }
}

/// Same options as web checkout: COD + Stripe (card / UPI) when key is set.
Future<String?> showPaymentMethodPicker(
  BuildContext context, {
  required String selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                children: [
                  if (kStripePublishableKey.isEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Card and UPI need your Stripe publishable key (pk_…): set '
                        'VITE_STRIPE_PUBLISHABLE_KEY=… in assets/env/app.env (no quotes), '
                        'or pass --dart-define=VITE_STRIPE_PUBLISHABLE_KEY=pk_test_…. '
                        'Stop the app and run again (not hot reload).',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppTheme.foregroundColor(
                            context,
                          ).withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                  _PaymentOptionRow(
                    label: paymentMethodLabel('cod'),
                    subtitle: paymentMethodDetailLine('cod')!,
                    icon: Icons.money_outlined,
                    isSelected: selected == 'cod',
                    onTap: () => Navigator.pop(ctx, 'cod'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOptionRow(
                    label: paymentMethodLabel('card'),
                    subtitle: paymentMethodDetailLine('card')!,
                    icon: Icons.credit_card_outlined,
                    isSelected: selected == 'card',
                    enabled: kStripePublishableKey.isNotEmpty,
                    onTap: () => Navigator.pop(ctx, 'card'),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOptionRow(
                    label: paymentMethodLabel('upi'),
                    subtitle: paymentMethodDetailLine('upi')!,
                    icon: Icons.phone_android_outlined,
                    isSelected: selected == 'upi',
                    enabled: kStripePublishableKey.isNotEmpty,
                    onTap: () => Navigator.pop(ctx, 'upi'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _PaymentOptionRow extends StatelessWidget {
  const _PaymentOptionRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor(context).withValues(alpha: 0.08)
                : AppTheme.backgroundColor(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor(context)
                  : AppTheme.foregroundColor(context).withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      (isSelected
                              ? AppTheme.primaryColor(context)
                              : AppTheme.foregroundColor(
                                  context,
                                ).withValues(alpha: 0.15))
                          .withValues(alpha: enabled ? 1 : 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isSelected
                      ? AppTheme.primaryForegroundColor(context)
                      : AppTheme.foregroundColor(
                          context,
                        ).withValues(alpha: enabled ? 0.8 : 0.4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foregroundColor(
                          context,
                        ).withValues(alpha: enabled ? 1 : 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.foregroundColor(
                          context,
                        ).withValues(alpha: enabled ? 0.6 : 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  size: 22,
                  color: AppTheme.primaryColor(context),
                )
              else if (!enabled)
                Text(
                  'Unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.foregroundColor(
                      context,
                    ).withValues(alpha: 0.5),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
