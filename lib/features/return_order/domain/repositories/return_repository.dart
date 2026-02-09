import '../entities/return_entity.dart';

abstract class ReturnRepository {
  Future<ReturnListResult> list({int limit = 20, int skip = 0});

  Future<ReturnEntity> getById(String id);
}

class ReturnListResult {
  const ReturnListResult({required this.returns, required this.total});
  final List<ReturnEntity> returns;
  final int total;
}
