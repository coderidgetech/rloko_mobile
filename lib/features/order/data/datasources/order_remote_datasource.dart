import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/order_dto.dart';

class OrderRemoteDataSource {
  OrderRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<OrderListResponseDto> list({int? limit, int? skip, String? status}) async {
    final query = <String, dynamic>{};
    if (limit != null) query['limit'] = limit;
    if (skip != null) query['skip'] = skip;
    if (status != null && status.isNotEmpty) query['status'] = status;
    final response = await _dio.get<Map<String, dynamic>>('/orders', queryParameters: query);
    final data = response.data;
    if (kDebugMode) debugPrint('[OrderRemoteDataSource] list response: $data');
    if (data == null) throw Exception('Invalid response');
    return OrderListResponseDto.fromJson(data);
  }

  Future<OrderDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return OrderDto.fromJson(data);
  }

  Future<OrderDto> getByOrderNumber(String orderNumber) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/tracking/$orderNumber');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return OrderDto.fromJson(data);
  }

  Future<List<OrderTrackingUpdateDto>> getTracking(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$orderId/tracking');
    final data = response.data;
    if (data == null) return [];
    final updatesRaw = data['updates'];
    if (updatesRaw is! List) return [];
    return (updatesRaw as List)
        .map((e) => OrderTrackingUpdateDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(String orderId, {String? reason}) async {
    await _dio.post<dynamic>(
      '/orders/$orderId/cancel',
      data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
  }

  Future<OrderDto> create(CreateOrderRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders',
        data: request.toJson(),
      );
      final data = response.data;
      if (kDebugMode) debugPrint('[OrderRemoteDataSource] create response: $data');
      if (data == null) throw Exception('Invalid response');
      return OrderDto.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[OrderRemoteDataSource] create DioException: type=${e.type}, '
            'status=${e.response?.statusCode}, message=${e.message}, response=${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<OrderDto> createGuest(CreateGuestOrderRequestDto request) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/orders/guest',
        data: request.toJson(),
        options: Options(extra: {'requiresAuth': false}),
      );
      final data = response.data;
      if (data == null) throw Exception('Invalid response');
      return OrderDto.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[OrderRemoteDataSource] createGuest DioException: ${e.response?.data}');
      }
      rethrow;
    }
  }
}
