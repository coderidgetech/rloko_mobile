import 'package:equatable/equatable.dart';

class ShippingMethodEntity extends Equatable {
  const ShippingMethodEntity({
    required this.id,
    required this.name,
    required this.carrier,
    required this.type,
    required this.baseCost,
    this.currency = 'USD',
    required this.estimatedDays,
    required this.isActive,
  });

  final String id;
  final String name;
  final String carrier;
  final String type;
  final double baseCost;
  final String currency;
  final int estimatedDays;
  final bool isActive;

  @override
  List<Object?> get props => [id];
}
