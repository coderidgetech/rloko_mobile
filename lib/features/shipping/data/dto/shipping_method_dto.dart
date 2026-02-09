import '../../domain/entities/shipping_method_entity.dart';

String _str(dynamic v) => v?.toString() ?? '';

class ShippingMethodDto {
  ShippingMethodDto({
    required this.id,
    required this.name,
    required this.carrier,
    required this.type,
    required this.baseCost,
    required this.estimatedDays,
    required this.isActive,
  });

  factory ShippingMethodDto.fromJson(Map<String, dynamic> json) {
    return ShippingMethodDto(
      id: _str(json['id']),
      name: json['name'] as String? ?? '',
      carrier: json['carrier'] as String? ?? '',
      type: json['type'] as String? ?? 'standard',
      baseCost: (json['base_cost'] as num?)?.toDouble() ?? 0,
      estimatedDays: json['estimated_days'] as int? ?? 5,
      isActive: json['is_active'] == true,
    );
  }

  final String id;
  final String name;
  final String carrier;
  final String type;
  final double baseCost;
  final int estimatedDays;
  final bool isActive;

  ShippingMethodEntity toEntity() => ShippingMethodEntity(
        id: id,
        name: name,
        carrier: carrier,
        type: type,
        baseCost: baseCost,
        estimatedDays: estimatedDays,
        isActive: isActive,
      );
}
