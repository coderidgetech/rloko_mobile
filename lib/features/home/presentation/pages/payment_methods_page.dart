import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../order/domain/entities/order_entity.dart';
import '../../../order/domain/usecases/order_usecases.dart';

/// Payment history + method info.
/// Fetches the user's orders to derive a transaction list.
class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  List<OrderEntity> _orders = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await sl<GetOrdersUseCase>().call(limit: 100);
      if (!mounted) return;
      setState(() {
        _orders = result.orders;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  static String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static IconData _methodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'stripe':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance;
      case 'cod':
      case 'cash_on_delivery':
        return Icons.payments_outlined;
      default:
        return Icons.payment;
    }
  }

  static String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'stripe':
        return 'Card / Stripe';
      case 'upi':
        return 'UPI';
      case 'cod':
      case 'cash_on_delivery':
        return 'Cash on Delivery';
      default:
        return method;
    }
  }

  static (Color bg, Color text) _statusStyle(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return (Colors.green.shade50, Colors.green.shade700);
      case 'pending':
        return (Colors.amber.shade50, Colors.amber.shade700);
      case 'failed':
      case 'refunded':
        return (Colors.red.shade50, Colors.red.shade700);
      default:
        return (
          AppTheme.mutedColor(context),
          AppTheme.mutedForegroundColor(context),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? _ErrorState(error: _error!, onRetry: _load)
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment History',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_orders.length} transaction${_orders.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_orders.isEmpty)
                        _EmptyState()
                      else
                        ..._orders.map((order) => _TransactionCard(
                              order: order,
                              formatDate: _formatDate,
                              methodIcon: _methodIcon,
                              methodLabel: _methodLabel,
                              statusStyle: _statusStyle,
                            )),
                      const SizedBox(height: 28),
                      _PaymentInfoSection(),
                    ],
                  ),
                ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({
    required this.order,
    required this.formatDate,
    required this.methodIcon,
    required this.methodLabel,
    required this.statusStyle,
  });

  final OrderEntity order;
  final String Function(String) formatDate;
  final IconData Function(String) methodIcon;
  final String Function(String) methodLabel;
  final (Color, Color) Function(BuildContext, String) statusStyle;

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor) = statusStyle(context, order.paymentStatus);

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                methodIcon(order.paymentMethod),
                size: 20,
                color: AppTheme.primaryColor(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '#${order.orderNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        '₹${order.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        methodLabel(order.paymentMethod),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                      Text(
                        formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      order.paymentStatus.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppTheme.mutedForegroundColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.mutedForegroundColor(context)),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedForegroundColor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your payment history will appear here after your first order.',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.go('/'),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(error, style: TextStyle(color: AppTheme.mutedForegroundColor(context))),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PaymentInfoSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mutedColor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How payments work',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.payments_outlined,
            title: 'Cash on Delivery',
            body: 'Pay the courier when your order arrives (where available).',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.credit_card,
            title: 'Card & UPI (Stripe)',
            body: 'Secure payment via Stripe at checkout. We never store your full card number.',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.lock_outline,
            title: 'Secure Payments',
            body: 'All transactions are encrypted and processed securely.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor(context)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppTheme.mutedForegroundColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
