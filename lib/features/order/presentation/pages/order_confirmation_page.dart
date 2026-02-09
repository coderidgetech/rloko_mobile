import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/usecases/order_usecases.dart';

class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  bool _loading = true;
  String? _error;
  String? _orderNumber;
  double? _total;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await sl<GetOrderByIdUseCase>().call(widget.orderId);
      if (mounted) {
        setState(() {
          _orderNumber = order.orderNumber;
          _total = order.total;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        title: const Text('Order confirmed'),
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: AppTheme.foregroundColor(context),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Back to home'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Thank you for your order!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Order number: $_orderNumber',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.mutedForegroundColor(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_total != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$${_total!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () =>
                              context.go('/orders/${widget.orderId}'),
                          child: const Text('View order'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.go('/'),
                          child: const Text('Continue shopping'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
