import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/app_header.dart';

/// We don’t collect card data on a separate “add card” screen — payment happens at checkout via Stripe.
/// This route remains for deep links; it forwards users to [PaymentMethodsPage] content.
class AddPaymentMethodPage extends StatelessWidget {
  const AddPaymentMethodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add a payment method',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(
              'Card and UPI details are entered securely when you place an order — not on this screen. '
              'Use checkout (cart) to pay with Stripe, or choose cash on delivery.',
              style: TextStyle(
                fontSize: 15,
                height: 1.45,
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.safePush('/cart'),
              child: const Text('Go to checkout'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => context.push('/payment-methods'),
              child: const Text('How payments work'),
            ),
          ],
        ),
      ),
    );
  }
}
