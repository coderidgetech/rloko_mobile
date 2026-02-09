import '../entities/promotion_entity.dart';

abstract class PromotionRepository {
  Future<List<PromotionEntity>> list({bool activeOnly = true});

  Future<ValidatePromotionResult> validate(String code, double subtotal);
}

class ValidatePromotionResult {
  const ValidatePromotionResult({
    required this.valid,
    this.promotion,
    this.discount,
  });

  final bool valid;
  final PromotionEntity? promotion;
  final double? discount;
}
