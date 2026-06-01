import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/region/currency_scope.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/safe_network_image.dart';
import '../../../product/presentation/widgets/empty_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/order_filter.dart';
import '../bloc/order_list_bloc.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  OrderListFilter _filter = OrderListFilter.active;
  bool _hasLoadedWhileAuthenticated = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Do not load here — wait until we know auth state so we never call GET /orders without a token
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      context.read<OrderListBloc>().add(const OrderListLoadMore());
    }
  }

  void _ensureOrdersLoadedIfAuthenticated() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    if (_hasLoadedWhileAuthenticated) return;
    _hasLoadedWhileAuthenticated = true;
    context.read<OrderListBloc>().add(OrderListLoadRequested(filter: _filter));
  }

  void _onFilterChanged(OrderListFilter f) {
    setState(() => _filter = f);
    _hasLoadedWhileAuthenticated = true;
    context.read<OrderListBloc>().add(OrderListLoadRequested(filter: f));
  }

  @override
  Widget build(BuildContext context) {
    // Only call GET /orders when user is authenticated, so we never get 401 from this page
    if (context.read<AuthBloc>().state is AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureOrdersLoadedIfAuthenticated();
      });
    }
    return Scaffold(
      backgroundColor: AppTheme.mutedColor(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/account');
            }
          },
        ),
        title: const Text('My Orders'),
        backgroundColor: AppTheme.backgroundColor(context),
        foregroundColor: AppTheme.foregroundColor(context),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return Column(
              children: [
                _buildTabs(),
                Expanded(
                  child: EmptyState(
                    title: 'Sign in to view orders',
                    subtitle: 'You need to be signed in to see your orders.',
                    icon: Icons.receipt_long_outlined,
                    actionLabel: 'Sign in',
                    onAction: () => context.push('/login', extra: '/orders'),
                  ),
                ),
              ],
            );
          }
          return Column(
            children: [
              _buildTabs(),
              Expanded(
                child: BlocBuilder<OrderListBloc, OrderListState>(
                  builder: (context, state) {
                    if (state is OrderListLoading) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    if (state is OrderListError) {
                      final isUnauth = state.message.contains('Sign in');
                      return EmptyState(
                        title: isUnauth
                            ? 'Sign in to view orders'
                            : 'Could not load orders',
                        subtitle: state.message,
                        icon: Icons.receipt_long_outlined,
                        actionLabel: isUnauth ? 'Sign in' : 'Retry',
                        onAction: () {
                          if (isUnauth) {
                            context.push('/login', extra: '/orders');
                          } else {
                            context
                                .read<OrderListBloc>()
                                .add(OrderListLoadRequested(filter: _filter));
                          }
                        },
                      );
                    }
                    if (state is OrderListLoaded) {
                      if (state.orders.isEmpty) {
                        return EmptyState(
                          title: 'No orders yet',
                          subtitle: 'Start shopping to see your orders here',
                          icon: Icons.receipt_long_outlined,
                          actionLabel: 'Continue shopping',
                          onAction: () => context.go('/'),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount:
                            state.orders.length + (state.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == state.orders.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          final order = state.orders[index];
                          return _OrderCard(
                            order: order,
                            onTap: () => context.push('/orders/${order.id}'),
                          );
                        },
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor(context),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.foregroundColor(context).withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(
        children: [
          _TabChip(
            label: 'Active',
            selected: _filter == OrderListFilter.active,
            onTap: () => _onFilterChanged(OrderListFilter.active),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'Completed',
            selected: _filter == OrderListFilter.completed,
            onTap: () => _onFilterChanged(OrderListFilter.completed),
          ),
          const SizedBox(width: 8),
          _TabChip(
            label: 'All Orders',
            selected: _filter == OrderListFilter.all,
            onTap: () => _onFilterChanged(OrderListFilter.all),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? AppTheme.primaryColor(context)
            : AppTheme.foregroundColor(context).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected
                    ? AppTheme.primaryForegroundColor(context)
                    : AppTheme.foregroundColor(context).withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final OrderEntity order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = order.items.isNotEmpty ? order.items.first.image : null;
    final itemCount = order.items.fold<int>(0, (s, i) => s + i.quantity);
    final statusDisplay = _statusDisplay(context, order.status);
    final isInTransit =
        order.status == 'shipped' || order.status == 'in-transit';
    final isDelivered = order.status == 'delivered';
    final deliveryDate = _formatDateShort(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppTheme.foregroundColor(context).withValues(alpha: 0.12),
        ),
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: order number + date | status pill with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(order.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.foregroundColor(context)
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusDisplay.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusDisplay.icon,
                          size: 16,
                          color: statusDisplay.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusDisplay.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: statusDisplay.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Product image + items + total + chevron
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: safeImageUrl(imageUrl),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 64,
                            height: 64,
                            color: AppTheme.mutedColor(context),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 24,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemCount item${itemCount == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.foregroundColor(context)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyScope.of(context).formatPrice(
                            order.total,
                            null,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.foregroundColor(context)
                        .withValues(alpha: 0.4),
                  ),
                ],
              ),
              // Delivery strip (in-transit / delivered)
              if (isInTransit) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor(context).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 16,
                        color: AppTheme.primaryColor(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Expected delivery: $deliveryDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.foregroundColor(context)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (isDelivered) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Delivered on $deliveryDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.foregroundColor(context)
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateShort(String iso) {
    try {
      final d = DateTime.parse(iso);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return iso;
    }
  }

  ({String label, Color color, IconData icon}) _statusDisplay(
    BuildContext context,
    String status,
  ) {
    switch (status) {
      case 'delivered':
        return (
          label: 'Delivered',
          color: Colors.green,
          icon: Icons.check_circle,
        );
      case 'shipped':
        return (
          label: 'Shipped',
          color: Colors.blue,
          icon: Icons.local_shipping,
        );
      case 'processing':
        return (
          label: 'Processing',
          color: Colors.orange,
          icon: Icons.schedule,
        );
      case 'cancelled':
        return (
          label: 'Cancelled',
          color: AppTheme.destructive,
          icon: Icons.cancel,
        );
      default:
        return (
          label: status,
          color: AppTheme.mutedForegroundColor(context),
          icon: Icons.receipt,
        );
    }
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return iso;
    }
  }
}
