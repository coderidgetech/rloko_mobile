import 'package:equatable/equatable.dart';

class PromotionEntity extends Equatable {
  const PromotionEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.value,
    this.minPurchase,
    this.maxDiscount,
    required this.startDate,
    required this.endDate,
    required this.usageCount,
    this.usageLimit,
    required this.isActive,
  });

  final String id;
  final String name;
  final String code;
  final String type; // percentage, fixed, free_shipping
  final double value;
  final double? minPurchase;
  final double? maxDiscount;
  final String startDate;
  final String endDate;
  final int usageCount;
  final int? usageLimit;
  final bool isActive;

  @override
  List<Object?> get props => [id, code];
}
