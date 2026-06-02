import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../domain/entities/rewards_transaction.dart';
import '../../domain/usecases/get_rewards_summary_usecase.dart';
import '../../domain/usecases/get_rewards_transactions_usecase.dart';
import '../../domain/usecases/redeem_rewards_usecase.dart';
import '../bloc/rewards_bloc.dart';

class RewardsPage extends StatelessWidget {
  const RewardsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RewardsBloc(
        getSummary: sl<GetRewardsSummaryUseCase>(),
        getTransactions: sl<GetRewardsTransactionsUseCase>(),
        redeem: sl<RedeemRewardsUseCase>(),
      )..add(const RewardsLoadRequested()),
      child: const _RewardsView(),
    );
  }
}

class _RewardsView extends StatefulWidget {
  const _RewardsView();

  @override
  State<_RewardsView> createState() => _RewardsViewState();
}

class _RewardsViewState extends State<_RewardsView> {
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: const AppHeader(showBackButton: true),
      body: BlocConsumer<RewardsBloc, RewardsState>(
        listener: (context, state) {
          if (state is RewardsRedeemSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Redeemed ${state.redeemedPoints} pts — ₹${(state.discountUsd * 83).toStringAsFixed(0)} discount!',
                ),
              ),
            );
            _pointsController.clear();
          }
          if (state is RewardsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is RewardsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is RewardsError && state is! RewardsLoaded) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }
          if (state is! RewardsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              const Text(
                'My Rewards',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),

              // Balance card
              _BalanceCard(summary: state.summary),
              const SizedBox(height: 16),

              // Redeem card
              _RedeemCard(
                pointsController: _pointsController,
                balance: state.summary.balance,
              ),
              const SizedBox(height: 24),

              // Transaction history
              Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundColor(context),
                ),
              ),
              const SizedBox(height: 12),

              if (state.transactions.isEmpty)
                _EmptyTransactions()
              else
                ...state.transactions.map((tx) => _TransactionRow(tx: tx)),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});
  final dynamic summary;

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Points Balance',
                style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${summary.balance}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('pts', style: TextStyle(color: Colors.white70, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '≈ ₹${(summary.pointsValueUsd * 83).toStringAsFixed(0)} value',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          if (summary.pointsRule != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                summary.pointsRule!,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _StatChip(
                label: 'Lifetime Earned',
                value: '${summary.rewardPoints} pts',
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Orders',
                value: '${summary.orderCount}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _RedeemCard extends StatelessWidget {
  const _RedeemCard({required this.pointsController, required this.balance});
  final TextEditingController pointsController;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.mutedColor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.foregroundColor(context).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.redeem_outlined, color: AppTheme.primaryColor(context), size: 18),
              const SizedBox(width: 8),
              Text(
                'Redeem Points',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foregroundColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '100 points = ₹83 discount · Minimum 100 points',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Points to redeem',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.foregroundColor(context).withValues(alpha: 0.2)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () {
                  final pts = int.tryParse(pointsController.text) ?? 0;
                  if (pts < 100) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Minimum 100 points')),
                    );
                    return;
                  }
                  if (pts > balance) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insufficient points balance')),
                    );
                    return;
                  }
                  context.read<RewardsBloc>().add(RewardsRedeemRequested(pts));
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Redeem'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.mutedForegroundColor(context)),
          const SizedBox(height: 12),
          Text(
            'No transactions yet',
            style: TextStyle(fontSize: 15, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 4),
          Text(
            'Points earned from purchases will appear here',
            style: TextStyle(fontSize: 12, color: AppTheme.mutedForegroundColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.tx});
  final RewardsTransaction tx;

  @override
  Widget build(BuildContext context) {
    final isEarned = tx.type == 'earned';
    final color = isEarned ? Colors.green.shade600 : Colors.red.shade600;
    final dt = tx.createdAt;
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.mutedColor(context).withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEarned ? Icons.add_rounded : Icons.remove_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.description,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foregroundColor(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 11, color: AppTheme.mutedForegroundColor(context)),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : '-'}${tx.points} pts',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
