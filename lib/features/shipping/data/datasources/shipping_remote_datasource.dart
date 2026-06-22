import '../../domain/entities/calculate_shipping_params.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/shipping_method_dto.dart';

class ShippingRemoteDataSource {
  ShippingRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Map<String, dynamic> _paramsToMap(CalculateShippingParams params) => {
        'country': params.country,
        if (params.state != null && params.state!.isNotEmpty) 'state': params.state,
        if (params.city != null && params.city!.isNotEmpty) 'city': params.city,
        if (params.address != null && params.address!.isNotEmpty) 'address': params.address,
        if (params.postalCode != null && params.postalCode!.isNotEmpty)
          'postal_code': params.postalCode,
        if (params.firstName != null && params.firstName!.isNotEmpty)
          'first_name': params.firstName,
        if (params.lastName != null && params.lastName!.isNotEmpty)
          'last_name': params.lastName,
        if (params.email != null && params.email!.isNotEmpty) 'email': params.email,
        if (params.phone != null && params.phone!.isNotEmpty) 'phone': params.phone,
        'subtotal': params.subtotal,
        if (params.weight != null && params.weight! > 0) 'weight': params.weight,
        if (params.items != null && params.items!.isNotEmpty)
          'items': params.items!
              .map((i) => {'product_id': i.productId, 'quantity': i.quantity})
              .toList(),
      };

  Future<List<ShippingMethodDto>> calculate(CalculateShippingParams params) async {
    final response = await _dio.post<dynamic>('/shipping/calculate', data: _paramsToMap(params));
    final data = response.data;
    if (data is Map && data['methods'] is List) {
      return (data['methods'] as List<dynamic>)
          .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (data is List) {
      return data
          .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<List<ShippingMethodDto>> listMethods({bool activeOnly = true}) async {
    final response = await _dio.get<dynamic>(
      '/shipping/methods',
      queryParameters: {'active_only': activeOnly},
    );
    final data = response.data;
    if (data is! List) return [];
    return data
        .map((e) => ShippingMethodDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
