import '../../domain/entities/rewards_summary.dart';

class RewardsSummaryDto {
  const RewardsSummaryDto({
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

  factory RewardsSummaryDto.fromJson(Map<String, dynamic> json) {
    return RewardsSummaryDto(
      orderCount: (json['order_count'] as num?)?.toInt() ?? 0,
      lifetimeSpend: (json['lifetime_spend'] as num?)?.toDouble() ?? 0,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      pointsValueUsd: (json['points_value_usd'] as num?)?.toDouble() ?? 0,
      pointsRule: json['points_rule'] as String?,
    );
  }

  RewardsSummary toEntity() => RewardsSummary(
        orderCount: orderCount,
        lifetimeSpend: lifetimeSpend,
        rewardPoints: rewardPoints,
        balance: balance,
        pointsValueUsd: pointsValueUsd,
        pointsRule: pointsRule,
      );
}
