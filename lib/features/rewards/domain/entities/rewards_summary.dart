import 'package:equatable/equatable.dart';

/// GET /rewards/summary
class RewardsSummary extends Equatable {
  const RewardsSummary({
    required this.orderCount,
    required this.lifetimeSpend,
    required this.rewardPoints,
    required this.balance,
    required this.pointsValueUsd,
    this.pointsRule,
  });

  final int orderCount;
  final double lifetimeSpend;
  final int rewardPoints;
  final int balance;
  final double pointsValueUsd;
  final String? pointsRule;

  @override
  List<Object?> get props => [orderCount, lifetimeSpend, rewardPoints, balance, pointsValueUsd, pointsRule];
}
