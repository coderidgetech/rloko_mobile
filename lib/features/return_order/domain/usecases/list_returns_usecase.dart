import '../repositories/return_repository.dart';

class ListReturnsUseCase {
  ListReturnsUseCase(this._repository);
  final ReturnRepository _repository;

  Future<ReturnListResult> call({int limit = 20, int skip = 0}) =>
      _repository.list(limit: limit, skip: skip);
}
