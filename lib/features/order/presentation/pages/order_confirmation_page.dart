import 'package:flutter/material.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart' show SafeCachedNetworkImage;
import '../../domain/entities/order_entity.dart';
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
  OrderEntity? _order;

  @override
  void initState() {
    super.initState();
    FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    _loadOrder();
  }

  @override
  void dispose() {
    FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      final order = await sl<GetOrderByIdUseCase>().call(widget.orderId);
      if (mounted) {
        setState(() {
          _order = order;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor(context),
        appBar: AppBar(
          title: const Text('Order confirmed'),
          backgroundColor: AppTheme.backgroundColor(context),
          foregroundColor: AppTheme.foregroundColor(context),
          automaticallyImplyLeading: false,
        ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
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
                          style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 16),
                      // Success icon + headline
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle, size: 72, color: Colors.green),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Thank you for your order!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Order ${_order?.orderNumber ?? ''}',
                        style: TextStyle(fontSize: 15, color: AppTheme.mutedForegroundColor(context)),
                        textAlign: TextAlign.center,
                      ),
                      if (_order != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${CurrencyScope.of(context).formatPrice(_order!.total, null)}',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 28),

                      // Items summary
                      if (_order != null && _order!.items.isNotEmpty) ...[
                        _SectionCard(
                          title: 'Items ordered',
                          child: Column(
                            children: _order!.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SafeCachedNetworkImage(
                                      imageUrl: item.image,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.productName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Size: ${item.size}  ×${item.quantity}',
                                          style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    CurrencyScope.of(context).formatPrice(item.price * item.quantity, null),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Shipping address
                      if (_order != null) ...[
                        _SectionCard(
                          title: 'Shipping to',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_order!.shippingInfo.firstName} ${_order!.shippingInfo.lastName}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _order!.shippingInfo.address,
                                style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                              ),
                              Text(
                                '${_order!.shippingInfo.city}, ${_order!.shippingInfo.state} ${_order!.shippingInfo.zipCode}',
                                style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                              ),
                              Text(
                                _order!.shippingInfo.country,
                                style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // CTAs
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => context.go('/orders/${widget.orderId}'),
                          child: const Text('View order'),
                        ),
                      ),
                      const SizedBox(height: 10),
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
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.mutedForegroundColor(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
