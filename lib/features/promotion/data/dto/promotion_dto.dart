import '../../domain/entities/promotion_entity.dart';

String _str(dynamic v) => v?.toString() ?? '';
String _date(dynamic v) =>
    v != null ? (DateTime.tryParse(v.toString())?.toIso8601String() ?? '') : '';

class PromotionDto {
  PromotionDto({
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

  factory PromotionDto.fromJson(Map<String, dynamic> json) {
    return PromotionDto(
      id: _str(json['id']),
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? 'percentage',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      minPurchase: (json['min_purchase'] as num?)?.toDouble(),
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      startDate: _date(json['start_date']),
      endDate: _date(json['end_date']),
      usageCount: json['usage_count'] as int? ?? 0,
      usageLimit: json['usage_limit'] as int?,
      isActive: json['is_active'] == true,
    );
  }

  final String id;
  final String name;
  final String code;
  final String type;
  final double value;
  final double? minPurchase;
  final double? maxDiscount;
  final String startDate;
  final String endDate;
  final int usageCount;
  final int? usageLimit;
  final bool isActive;

  PromotionEntity toEntity() => PromotionEntity(
        id: id,
        name: name,
        code: code,
        type: type,
        value: value,
        minPurchase: minPurchase,
        maxDiscount: maxDiscount,
        startDate: startDate,
        endDate: endDate,
        usageCount: usageCount,
        usageLimit: usageLimit,
        isActive: isActive,
      );
}
