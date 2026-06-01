import '../../domain/entities/redeem_result.dart';

class RedeemResultDto {
  const RedeemResultDto({
    required this.redeemedPoints,
    required this.discountUsd,
    required this.newBalance,
  });

  final int redeemedPoints;
  final double discountUsd;
  final int newBalance;

  factory RedeemResultDto.fromJson(Map<String, dynamic> json) => RedeemResultDto(
        redeemedPoints: (json['redeemed_points'] as num?)?.toInt() ?? 0,
        discountUsd: (json['discount_usd'] as num?)?.toDouble() ?? 0,
        newBalance: (json['new_balance'] as num?)?.toInt() ?? 0,
      );

  RedeemResult toEntity() => RedeemResult(
        redeemedPoints: redeemedPoints,
        discountUsd: discountUsd,
        newBalance: newBalance,
      );
}
