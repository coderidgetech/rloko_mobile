import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/order_repository.dart';
import '../bloc/order_detail_bloc.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  bool _showReturnForm = false;
  String _returnReason = 'wrong_size';
  final _returnDescController = TextEditingController();
  bool _submittingReturn = false;

  static const _returnReasons = [
    ('wrong_size', 'Wrong size'),
    ('defective', 'Defective / damaged'),
    ('not_as_described', 'Not as described'),
    ('changed_mind', 'Changed mind'),
    ('other', 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    context
        .read<OrderDetailBloc>()
        .add(OrderDetailLoadRequested(widget.orderId));
  }

  @override
  void dispose() {
    _returnDescController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mutedColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
        ),
        title: const Text('Order Details'),
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: AppTheme.foregroundColor(context),
      ),
      body: BlocConsumer<OrderDetailBloc, OrderDetailState>(
        listener: (context, state) {
          if (state is OrderDetailCancelSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order cancelled')),
            );
            context.pop();
          }
          if (state is OrderDetailReturnSuccess) {
            setState(() {
              _showReturnForm = false;
              _submittingReturn = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Return request submitted')),
            );
          }
          if (state is OrderDetailReturnError) {
            setState(() => _submittingReturn = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is OrderDetailLoading) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }
          if (state is OrderDetailError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.mutedForegroundColor(context)),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context
                          .read<OrderDetailBloc>()
                          .add(OrderDetailLoadRequested(widget.orderId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is OrderDetailLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderStatusCard(order: state.order),
                  const SizedBox(height: 16),
                  _OrderItemsCard(items: state.order.items),
                  const SizedBox(height: 16),
                  _ShippingAddressCard(shipping: state.order.shippingInfo),
                  const SizedBox(height: 16),
                  _PaymentMethodCard(paymentMethod: state.order.paymentMethod),
                  const SizedBox(height: 16),
                  _OrderSummaryCard(order: state.order),
                  const SizedBox(height: 16),
                  _OrderActionButtons(),
                  if (_isTrackable(state.order)) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/tracking/${state.order.id}'),
                      icon: const Icon(Icons.local_shipping_outlined, size: 18),
                      label: const Text('Track Order'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  if (state.trackingUpdates.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _TrackingSection(updates: state.trackingUpdates),
                  ],
                  if (_canCancel(state.order)) ...[
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: () => _showCancelDialog(context, state.order.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.destructive,
                        side: const BorderSide(color: AppTheme.destructive),
                      ),
                      child: const Text('Cancel order'),
                    ),
                  ],
                  if (state.order.status == 'delivered') ...[
                    const SizedBox(height: 16),
                    _buildReviewCard(context, state.order),
                    const SizedBox(height: 12),
                    _buildReturnCard(context, state.order),
                  ],
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  bool _canCancel(OrderEntity order) {
    return order.status == 'pending' || order.status == 'processing';
  }

  bool _isTrackable(OrderEntity order) {
    return const {'shipped', 'in_transit', 'in-transit', 'out_for_delivery', 'delivered'}
        .contains(order.status.toLowerCase());
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'This action cannot be undone. Do you want to cancel this order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context
                  .read<OrderDetailBloc>()
                  .add(const OrderDetailCancelRequested());
            },
            style: FilledButton.styleFrom(backgroundColor: AppTheme.destructive),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, OrderEntity order) {
    if (order.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_border_rounded, size: 20, color: AppTheme.primaryColor(context)),
              const SizedBox(width: 8),
              const Text('Write a Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Share your thoughts on the items you received.',
            style: TextStyle(fontSize: 13, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => context.push(
                '/reviews/write/${item.productId}',
                extra: {'productName': item.productName},
              ),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SafeCachedNetworkImage(
                        imageUrl: item.image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.chevron_right, size: 18, color: AppTheme.mutedForegroundColor(context)),
                  ],
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildReturnCard(BuildContext context, OrderEntity order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.undo_outlined, size: 18, color: AppTheme.foregroundColor(context)),
              const SizedBox(width: 8),
              const Text('Return Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          if (!_showReturnForm) ...[
            const SizedBox(height: 12),
            Text(
              'Not satisfied with your purchase? You can request a return within 30 days.',
              style: TextStyle(fontSize: 13, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => setState(() => _showReturnForm = true),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
                child: const Text('Request Return'),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: _returnReason,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                borderRadius: BorderRadius.circular(12),
                items: _returnReasons
                    .map((r) => DropdownMenuItem(value: r.$1, child: Text(r.$2, style: const TextStyle(fontSize: 14))))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _returnReason = v);
                },
              ),
            ),
            const SizedBox(height: 12),
            Text('Description (optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.foregroundColor(context).withValues(alpha: 0.7))),
            const SizedBox(height: 8),
            TextField(
              controller: _returnDescController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Describe the issue...',
                hintStyle: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.4)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submittingReturn ? null : () => setState(() => _showReturnForm = false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _submittingReturn ? null : () => _submitReturn(context, order),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: _submittingReturn
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Return'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _submitReturn(BuildContext context, OrderEntity order) {
    setState(() => _submittingReturn = true);
    final items = order.items
        .map((item) => {
              'product_id': item.productId,
              'product_name': item.productName,
              'image': item.image,
              'price': item.price,
              'size': item.size,
              'quantity': item.quantity,
            })
        .toList();
    context.read<OrderDetailBloc>().add(
          OrderDetailReturnRequested(
            items: items,
            reason: _returnReason,
            description: _returnDescController.text.trim(),
          ),
        );
  }
}

/// Match React: Order Status Card - order number, placed date, status pill, in-transit/delivered box
/// Returns the customer-facing label for a refund-related payment status, or null
/// when there's nothing to show (e.g. paid/pending/failed).
String? _refundLabel(String paymentStatus) {
  switch (paymentStatus.toLowerCase()) {
    case 'refunded':
      return 'Refunded';
    case 'partially_refunded':
      return 'Partially refunded';
    case 'refunding':
      return 'Refund in progress';
    default:
      return null;
  }
}

class _RefundBadge extends StatelessWidget {
  const _RefundBadge({required this.paymentStatus});
  final String paymentStatus;

  @override
  Widget build(BuildContext context) {
    final label = _refundLabel(paymentStatus);
    if (label == null) return const SizedBox.shrink();
    final status = paymentStatus.toLowerCase();
    final (Color color, Color bg) = switch (status) {
      'refunding' => (Colors.blue.shade700, Colors.blue.shade50),
      'partially_refunded' => (Colors.amber.shade800, Colors.amber.shade50),
      _ => (Colors.green.shade700, Colors.green.shade50),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});
  final OrderEntity order;

  static String _formatDateShort(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  static String _estimatedDelivery(String iso) {
    try {
      final d = DateTime.parse(iso).add(const Duration(days: 5));
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInTransit = order.status == 'shipped' || order.status == 'in-transit';
    final isDelivered = order.status == 'delivered';
    final (bgColor, textColor, icon) = _statusStyle(context, order.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Placed on ${_formatDateShort(order.createdAt)}',
                      style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 20, color: textColor),
                        const SizedBox(width: 6),
                        Text(
                          order.status.isEmpty
                              ? order.status
                              : order.status.replaceAll('-', ' ').toLowerCase().replaceRange(0, 1, order.status[0].toUpperCase()),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textColor),
                        ),
                      ],
                    ),
                  ),
                  if (_refundLabel(order.paymentStatus) != null) ...[
                    const SizedBox(height: 6),
                    _RefundBadge(paymentStatus: order.paymentStatus),
                  ],
                ],
              ),
            ],
          ),
          if (isInTransit) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 18, color: AppTheme.primaryColor(context)),
                      const SizedBox(width: 8),
                      Text('Estimated Delivery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.primaryColor(context))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(_estimatedDelivery(order.createdAt), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('Tracking: ${order.trackingNumber}', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                  ],
                ],
              ),
            ),
          ],
          if (isDelivered) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      Text('Delivered', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.green.shade700)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Delivered on ${_formatDateShort(order.updatedAt)}', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  (Color, Color, IconData) _statusStyle(BuildContext context, String status) {
    switch (status) {
      case 'delivered':
        return (Colors.green.shade50, Colors.green.shade700, Icons.check_circle);
      case 'shipped':
      case 'in-transit':
        return (Colors.blue.shade50, Colors.blue.shade700, Icons.local_shipping);
      case 'processing':
        return (Colors.orange.shade50, Colors.orange.shade700, Icons.schedule);
      case 'cancelled':
        return (Colors.red.shade50, Colors.red.shade700, Icons.cancel);
      default:
        return (AppTheme.foregroundColor(context).withValues(alpha: 0.05), AppTheme.foregroundColor(context).withValues(alpha: 0.6), Icons.receipt);
    }
  }
}

/// Match React: Order Items card - Package icon + "Order Items (n)", 80x80 rounded-lg, name, Size, Qty, price, border between
class _OrderItemsCard extends StatelessWidget {
  const _OrderItemsCard({required this.items});
  final List<OrderItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, size: 18, color: AppTheme.foregroundColor(context)),
              const SizedBox(width: 8),
              Text('Order Items (${items.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final showBorder = index < items.length - 1;
            return Padding(
              padding: EdgeInsets.only(bottom: showBorder ? 12 : 0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: safeImageUrl(item.image),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: AppTheme.mutedColor(context),
                                child: const Icon(Icons.image),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text('Size: ${item.size}', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Qty: ${item.quantity}', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
                                Text(
                                  CurrencyScope.of(context).formatPrice(item.price * item.quantity, null),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showBorder) ...[
                    const SizedBox(height: 12),
                    Divider(height: 1, color: AppTheme.foregroundColor(context).withValues(alpha: 0.08)),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Match React: Shipping Address card - MapPin, inner bg-muted/30 rounded-xl
class _ShippingAddressCard extends StatelessWidget {
  const _ShippingAddressCard({required this.shipping});
  final ShippingInfoEntity shipping;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: AppTheme.foregroundColor(context)),
              const SizedBox(width: 8),
              const Text('Shipping Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mutedColor(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${shipping.firstName} ${shipping.lastName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(shipping.address, style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                Text('${shipping.city}, ${shipping.state} ${shipping.zipCode}', style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                if (shipping.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6)),
                      const SizedBox(width: 6),
                      Text(shipping.phone, style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Match React: Payment Method card - CreditCard, inner box, CheckCircle
class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({required this.paymentMethod});
  final String paymentMethod;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_outlined, size: 18, color: AppTheme.foregroundColor(context)),
              const SizedBox(width: 8),
              const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mutedColor(context).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paymentMethod.isNotEmpty ? paymentMethod : '—', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('**** **** **** ****', style: TextStyle(fontSize: 12, color: AppTheme.foregroundColor(context).withValues(alpha: 0.5))),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, size: 18, color: Colors.green.shade600),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Match React: Order Summary card - Subtotal, Shipping, Tax, Total (primary)
class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});
  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          _SummaryRow(label: 'Subtotal', value: CurrencyScope.of(context).formatPrice(order.subtotal, null)),
          if (order.discount > 0) _SummaryRow(label: 'Discount', value: '-${CurrencyScope.of(context).formatPrice(order.discount, null)}'),
          _SummaryRow(
            label: 'Shipping',
            value: order.shippingCost == 0 ? 'FREE' : CurrencyScope.of(context).formatPrice(order.shippingCost, null),
            valueGreen: order.shippingCost == 0,
          ),
          _SummaryRow(label: 'Tax', value: CurrencyScope.of(context).formatPrice(order.tax, null)),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              Text(CurrencyScope.of(context).formatPrice(order.total, null), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryColor(context))),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.valueGreen = false});
  final String label;
  final String value;
  final bool valueGreen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: AppTheme.foregroundColor(context).withValues(alpha: 0.6))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueGreen ? Colors.green.shade600 : null)),
        ],
      ),
    );
  }
}

/// Match React: Contact Support (primary), Download Invoice (outlined)
class _OrderActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => context.push('/help'),
            icon: const Icon(Icons.phone, size: 18),
            label: const Text('Contact Support'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Request your invoice via Contact Us')),
              );
              context.push('/contact');
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download Invoice'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackingSection extends StatelessWidget {
  const _TrackingSection({required this.updates});
  final List<OrderTrackingUpdateEntity> updates;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tracking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...updates.asMap().entries.map((e) {
              final i = e.key;
              final u = e.value;
              final isLast = i == updates.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor(context),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: AppTheme.mutedForegroundColor(context),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              u.status,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (u.description != null)
                              Text(
                                u.description!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedForegroundColor(context),
                                ),
                              ),
                            if (u.location != null && u.location!.isNotEmpty)
                              Text(
                                u.location!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedForegroundColor(context),
                                ),
                              ),
                            Text(
                              _formatDate(u.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForegroundColor(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}
