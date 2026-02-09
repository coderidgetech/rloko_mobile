import '../repositories/promotion_repository.dart';

class ValidatePromotionUseCase {
  ValidatePromotionUseCase(this._repository);
  final PromotionRepository _repository;

  Future<ValidatePromotionResult> call(String code, double subtotal) =>
      _repository.validate(code, subtotal);
}
