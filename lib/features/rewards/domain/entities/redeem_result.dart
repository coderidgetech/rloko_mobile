import 'package:equatable/equatable.dart';

class RedeemResult extends Equatable {
  const RedeemResult({
    required this.redeemedPoints,
    required this.discountUsd,
    required this.newBalance,
  });

  final int redeemedPoints;
  final double discountUsd;
  final int newBalance;

  @override
  List<Object?> get props => [redeemedPoints, discountUsd, newBalance];
}
