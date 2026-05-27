import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/sign_in_to_continue_panel.dart';
import '../../../rewards/domain/entities/rewards_summary.dart';
import '../../../rewards/domain/usecases/get_rewards_summary_usecase.dart';

/// Rloco Rewards — live data from GET /rewards/summary (order history).
class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage> {
  RewardsSummary? _summary;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final a = context.read<AuthBloc>().state;
      if (a is AuthAuthenticated) {
        _load();
      } else {
        setState(() => _loading = false);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await sl<GetRewardsSummaryUseCase>()();
      if (mounted) {
        setState(() {
          _summary = s;
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
      appBar: const AppHeader(showBackButton: true),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (p, c) => p is! AuthAuthenticated && c is AuthAuthenticated,
        listener: (_, __) {
          setState(() {
            _summary = null;
            _error = null;
            _loading = true;
          });
          _load();
        },
        child: _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final auth = context.watch<AuthBloc>().state;
    if (auth is AuthInitial || auth is AuthLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (auth is! AuthAuthenticated) {
      return const SignInToContinuePanel(
        title: 'Sign in to see your rewards',
        subtitle: 'Points and order totals are based on your purchase history.',
        returnPath: '/rewards',
        icon: Icons.card_giftcard_outlined,
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final s = _summary!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Rloco Rewards',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Based on your completed orders (excluding cancelled).',
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor(context).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor(context).withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${s.rewardPoints}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Reward points',
                  style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _StatRow(
            label: 'Orders (non-cancelled)',
            value: '${s.orderCount}',
          ),
          const SizedBox(height: 8),
          _StatRow(
            label: 'Lifetime order total',
            value: s.lifetimeSpend.toStringAsFixed(2),
          ),
          if (s.pointsRule != null) ...[
            const SizedBox(height: 20),
            Text(
              s.pointsRule!,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.foregroundColor(context).withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Redemption options will appear here as the program grows. For now, your balance reflects purchase activity only.',
            style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: AppTheme.mutedForegroundColor(context))),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
