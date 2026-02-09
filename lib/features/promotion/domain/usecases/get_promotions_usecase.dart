import '../entities/promotion_entity.dart';
import '../repositories/promotion_repository.dart';

class GetPromotionsUseCase {
  GetPromotionsUseCase(this._repository);
  final PromotionRepository _repository;

  Future<List<PromotionEntity>> call({bool activeOnly = true}) =>
      _repository.list(activeOnly: activeOnly);
}
