import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/order_usecases.dart';

/// Dedicated order tracking page — shows full timeline for a single order.
/// Accessed via /tracking/:orderId (linked from order detail for shipped orders).
class OrderTrackingPage extends StatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends State<OrderTrackingPage> {
  OrderEntity? _order;
  List<OrderTrackingUpdateEntity> _updates = [];
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
      final order = await sl<GetOrderByIdUseCase>().call(widget.orderId);
      List<OrderTrackingUpdateEntity> updates = [];
      try {
        updates = await sl<GetOrderTrackingUseCase>().call(widget.orderId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _order = order;
        _updates = updates;
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

  static const _statusOrder = [
    'pending',
    'processing',
    'shipped',
    'in_transit',
    'out_for_delivery',
    'delivered',
  ];

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'in_transit':
      case 'in-transit':
        return 'In Transit';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  static String _formatDateTime(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    final amPm = d.hour < 12 ? 'AM' : 'PM';
    return '${months[d.month - 1]} ${d.day}, ${d.year}  $hour:$min $amPm';
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.shopping_bag_outlined;
      case 'processing':
        return Icons.inventory_2_outlined;
      case 'shipped':
        return Icons.local_shipping_outlined;
      case 'in_transit':
      case 'in-transit':
        return Icons.route_outlined;
      case 'out_for_delivery':
        return Icons.delivery_dining_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  int _currentStep(String status) {
    final idx = _statusOrder.indexWhere((s) => s == status.toLowerCase());
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : _error != null
              ? _buildError(context)
              : _buildContent(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final order = _order!;
    final currentStep = _currentStep(order.status);
    final isCancelled = order.status.toLowerCase() == 'cancelled';

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isCancelled
                          ? Colors.red.shade50
                          : AppTheme.primaryColor(context).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCancelled ? Icons.cancel_outlined : Icons.local_shipping_outlined,
                      size: 28,
                      color: isCancelled ? Colors.red : AppTheme.primaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Order ${order.orderNumber}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  if (order.trackingNumber != null)
                    Text(
                      'Tracking: ${order.trackingNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppTheme.mutedForegroundColor(context),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress bar (only for non-cancelled)
            if (!isCancelled) ...[
              _ProgressBar(currentStep: currentStep, totalSteps: _statusOrder.length),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order Placed',
                    style: TextStyle(fontSize: 10, color: AppTheme.mutedForegroundColor(context)),
                  ),
                  Text(
                    'Delivered',
                    style: TextStyle(fontSize: 10, color: AppTheme.mutedForegroundColor(context)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Status steps
            const Text(
              'Status Updates',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (_updates.isNotEmpty)
              _TrackingTimeline(updates: _updates, formatDateTime: _formatDateTime)
            else
              _DefaultStatusTimeline(
                order: order,
                statusOrder: _statusOrder,
                currentStep: currentStep,
                statusLabel: _statusLabel,
                statusIcon: _statusIcon,
                formatDateTime: _formatDateTime,
              ),

            const SizedBox(height: 24),

            // Shipping details card
            _ShippingCard(order: order),

            const SizedBox(height: 16),

            // View order button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.push('/orders/${order.id}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Order Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep, required this.totalSteps});
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final progress = totalSteps > 1 ? currentStep / (totalSteps - 1) : 1.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: AppTheme.borderColor(context),
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor(context)),
      ),
    );
  }
}

class _TrackingTimeline extends StatelessWidget {
  const _TrackingTimeline({
    required this.updates,
    required this.formatDateTime,
  });
  final List<OrderTrackingUpdateEntity> updates;
  final String Function(String) formatDateTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: updates.asMap().entries.map((entry) {
        final i = entry.key;
        final update = entry.value;
        final isFirst = i == 0;
        final isLast = i == updates.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 28,
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: isFirst ? AppTheme.primaryColor(context) : AppTheme.borderColor(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isFirst
                              ? AppTheme.primaryColor(context)
                              : AppTheme.borderColor(context),
                          width: 2,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppTheme.borderColor(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                          color: isFirst ? AppTheme.foregroundColor(context) : AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                      if (update.description != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          update.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                      ],
                      if (update.location != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: AppTheme.mutedForegroundColor(context)),
                            const SizedBox(width: 3),
                            Text(
                              update.location!,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.mutedForegroundColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        formatDateTime(update.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedForegroundColor(context).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _DefaultStatusTimeline extends StatelessWidget {
  const _DefaultStatusTimeline({
    required this.order,
    required this.statusOrder,
    required this.currentStep,
    required this.statusLabel,
    required this.statusIcon,
    required this.formatDateTime,
  });

  final OrderEntity order;
  final List<String> statusOrder;
  final int currentStep;
  final String Function(String) statusLabel;
  final IconData Function(String) statusIcon;
  final String Function(String) formatDateTime;

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final visibleSteps = isCancelled
        ? [order.status]
        : statusOrder.sublist(0, currentStep + 1).reversed.toList();

    return Column(
      children: visibleSteps.asMap().entries.map((entry) {
        final i = entry.key;
        final status = entry.value;
        final isFirst = i == 0;
        final isLast = i == visibleSteps.length - 1;
        final isCompleted = isFirst || (!isCancelled);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isFirst
                            ? AppTheme.primaryColor(context)
                            : isCompleted
                                ? AppTheme.primaryColor(context).withValues(alpha: 0.12)
                                : AppTheme.borderColor(context),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        statusIcon(status),
                        size: 18,
                        color: isFirst
                            ? Colors.white
                            : AppTheme.primaryColor(context).withValues(alpha: isCompleted ? 0.8 : 0.3),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: AppTheme.borderColor(context),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 6, bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusLabel(status),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isFirst ? FontWeight.bold : FontWeight.w500,
                          color: isFirst
                              ? AppTheme.foregroundColor(context)
                              : AppTheme.mutedForegroundColor(context),
                        ),
                      ),
                      if (isFirst) ...[
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(order.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                      ] else if (status == 'pending') ...[
                        const SizedBox(height: 2),
                        Text(
                          formatDateTime(order.createdAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.mutedForegroundColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  const _ShippingCard({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final info = order.shippingInfo;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mutedColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primaryColor(context)),
              const SizedBox(width: 8),
              const Text(
                'Delivery Address',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${info.firstName} ${info.lastName}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            '${info.address}, ${info.city}, ${info.state} ${info.zipCode}',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context), height: 1.4),
          ),
          Text(
            info.country,
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
          ),
          if (info.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info.phone,
              style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
            ),
          ],
        ],
      ),
    );
  }
}
