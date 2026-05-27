import '../entities/return_entity.dart';

abstract class ReturnRepository {
  Future<ReturnListResult> list({int limit = 20, int skip = 0});

  Future<ReturnEntity> getById(String id);

  Future<ReturnEntity> create({
    required String orderId,
    required List<Map<String, dynamic>> items,
    required String reason,
    String description,
  });
}

class ReturnListResult {
  const ReturnListResult({required this.returns, required this.total});
  final List<ReturnEntity> returns;
  final int total;
}
