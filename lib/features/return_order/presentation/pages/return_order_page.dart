import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/return_entity.dart';
import '../bloc/return_order_cubit.dart';

class ReturnOrderPage extends StatelessWidget {
  const ReturnOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReturnOrderCubit>(
      create: (_) => sl<ReturnOrderCubit>()..loadReturns(),
      child: const _ReturnOrderView(),
    );
  }
}

class _ReturnOrderView extends StatelessWidget {
  const _ReturnOrderView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Returns'),
      ),
      body: BlocBuilder<ReturnOrderCubit, ReturnOrderState>(
        builder: (context, state) {
          if (state is ReturnOrderLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ReturnOrderError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<ReturnOrderCubit>().loadReturns(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is ReturnOrderLoaded) {
            final returns = state.returns;
            if (returns.isEmpty) {
              return const Center(child: Text('No returns found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: returns.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _ReturnCard(returnEntity: returns[index]),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  const _ReturnCard({required this.returnEntity});

  final ReturnEntity returnEntity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${returnEntity.orderNumber}',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                _StatusChip(status: returnEntity.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reason: ${returnEntity.reason}',
              style: theme.textTheme.bodyMedium,
            ),
            if (returnEntity.description != null &&
                returnEntity.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                returnEntity.description!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Refund: \$${returnEntity.refundAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  'Refund Status: ${returnEntity.refundStatus}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Created: ${returnEntity.createdAt}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color _colorForStatus() {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colorForStatus().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorForStatus(), width: 0.8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          color: _colorForStatus(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
