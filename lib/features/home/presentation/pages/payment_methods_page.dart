import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';

/// Payment methods list – design matches React MobilePaymentMethodsPage (mock; no saved-methods API).
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final List<_PaymentMethod> _methods = [
    _PaymentMethod(
      id: '1',
      type: 'card',
      cardNumber: '**** **** **** 4532',
      cardHolder: 'PRANEETH KUMAR',
      expiryDate: '12/26',
      isDefault: true,
    ),
    _PaymentMethod(
      id: '2',
      type: 'upi',
      upiId: 'praneeth@paytm',
      isDefault: false,
    ),
  ];

  void _setDefault(String id) {
    setState(() {
      for (var m in _methods) {
        m.isDefault = m.id == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
  }

  void _delete(String id) {
    setState(() => _methods.removeWhere((m) => m.id == id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment method removed')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.muted.withValues(alpha: 0.3),
      appBar: const AppHeader(showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Methods',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your saved payment options',
              style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => context.push('/add-payment-method'),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Payment Method'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_methods.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(Icons.credit_card, size: 48, color: AppTheme.foreground.withValues(alpha: 0.2)),
                      const SizedBox(height: 12),
                      Text(
                        'No payment methods saved',
                        style: TextStyle(color: AppTheme.mutedForeground),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._methods.asMap().entries.map((e) => _buildCard(e.value)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Text(
                '💳 Your payment information is encrypted and secure. We never store your CVV.',
                style: TextStyle(fontSize: 14, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(_PaymentMethod method) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.foreground.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (method.type == 'card') ...[
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primary,
                          AppTheme.primary.withValues(alpha: 0.6),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card, size: 24, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method.cardNumber!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          method.cardHolder!,
                          style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                        ),
                        Text(
                          'Expires ${method.expiryDate}',
                          style: TextStyle(fontSize: 12, color: AppTheme.mutedForeground.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  if (method.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF9333EA), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'UPI',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UPI Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          method.upiId!,
                          style: TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
                        ),
                      ],
                    ),
                  ),
                  if (method.isDefault)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, size: 12, color: AppTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (!method.isDefault) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _setDefault(method.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primary,
                        side: BorderSide.none,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Set as Default'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _delete(method.id),
                    icon: Icon(Icons.delete_outline, size: 20, color: Colors.red.shade600),
                    style: IconButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade200),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentMethod {
  _PaymentMethod({
    required this.id,
    required this.type,
    this.cardNumber,
    this.cardHolder,
    this.expiryDate,
    this.upiId,
    required this.isDefault,
  });
  final String id;
  final String type;
  final String? cardNumber;
  final String? cardHolder;
  final String? expiryDate;
  final String? upiId;
  bool isDefault;
}
