import '../entities/return_entity.dart';
import '../repositories/return_repository.dart';

class CreateReturnUseCase {
  CreateReturnUseCase(this._repository);
  final ReturnRepository _repository;

  Future<ReturnEntity> call({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String description = '',
  }) =>
      _repository.create(
        orderId: orderId,
        items: items,
        reason: reason,
        description: description,
      );
}
