import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/rewards_summary.dart';
import '../../domain/entities/rewards_transaction.dart';

class RewardsRemoteDataSource {
  RewardsRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<RewardsSummary> getSummary() async {
    final response = await _dio.get<Map<String, dynamic>>('/rewards/summary');
    final data = response.data;
    if (data == null) throw Exception('Invalid rewards response');
    return RewardsSummary.fromJson(data);
  }

  Future<({List<RewardsTransaction> transactions, int total})> getTransactions({
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '/rewards/transactions',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    final data = response.data;
    if (data is! Map) return (transactions: <RewardsTransaction>[], total: 0);
    final raw = data['transactions'];
    if (raw is! List) return (transactions: <RewardsTransaction>[], total: 0);
    final list = raw
        .map((e) => RewardsTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (data['total'] is int) ? data['total'] as int : list.length;
    return (transactions: list, total: total);
  }

  Future<Map<String, dynamic>> redeemPoints(int points) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/rewards/redeem',
      data: {'points': points},
    );
    return response.data ?? {};
  }
}
