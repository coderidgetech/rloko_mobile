import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/calculate_tax_params.dart';

class TaxRemoteDataSource {
  TaxRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Map<String, dynamic> _paramsToMap(CalculateTaxParams params) => {
        'country': params.country,
        if (params.state != null && params.state!.isNotEmpty) 'state': params.state,
        if (params.city != null && params.city!.isNotEmpty) 'city': params.city,
        if (params.postalCode != null && params.postalCode!.isNotEmpty)
          'postal_code': params.postalCode,
        'subtotal': params.subtotal,
      };

  /// POST /tax/calculate → `{ "tax_amount": <num>, "rate": {...} }`.
  /// Also tolerates a `tax` key for parity with web's fallback handling.
  Future<double> calculate(CalculateTaxParams params) async {
    final response =
        await _dio.post<dynamic>('/tax/calculate', data: _paramsToMap(params));
    final data = response.data;
    if (data is Map) {
      final raw = data['tax_amount'] ?? data['tax'];
      if (raw is num) return raw.toDouble();
    }
    return 0;
  }
}
