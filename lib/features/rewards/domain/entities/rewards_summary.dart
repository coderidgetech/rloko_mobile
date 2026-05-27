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

  factory RewardsSummary.fromJson(Map<String, dynamic> json) {
    return RewardsSummary(
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      lifetimeSpend: (json['lifetime_spend'] as num?)?.toDouble() ?? 0,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      pointsValueUsd: (json['points_value_usd'] as num?)?.toDouble() ?? 0,
      pointsRule: json['points_rule'] as String?,
    );
  }

  @override
  List<Object?> get props => [orderCount, lifetimeSpend, rewardPoints, balance, pointsValueUsd, pointsRule];
}
