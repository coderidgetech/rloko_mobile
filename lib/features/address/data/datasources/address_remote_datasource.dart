import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/dio_client.dart';
import '../dto/address_dto.dart';

class AddressRemoteDataSource {
  AddressRemoteDataSource(this._client);

  final DioClient _client;
  dynamic get _dio => _client.dio;

  Future<List<AddressDto>> list() async {
    try {
      final response = await _dio.get<dynamic>('/addresses');
      final data = response.data;
      if (kDebugMode) debugPrint('[AddressRemoteDataSource] list response: $data');
      if (data is! List) return [];
      return (data as List)
          .map((e) => AddressDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AddressRemoteDataSource] list DioException: type=${e.type}, '
            'status=${e.response?.statusCode}, message=${e.message}, response=${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<AddressDto> getById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/addresses/$id');
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return AddressDto.fromJson(data);
  }

  Future<AddressDto> create(AddressDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>('/addresses', data: dto.toJson());
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return AddressDto.fromJson(data);
  }

  Future<AddressDto> update(String id, AddressDto dto) async {
    final response = await _dio.put<Map<String, dynamic>>('/addresses/$id', data: dto.toJson());
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    return AddressDto.fromJson(data);
  }

  Future<void> delete(String id) async {
    await _dio.delete<void>('/addresses/$id');
  }

  Future<void> setDefault(String id) async {
    await _dio.put<void>('/addresses/$id/default');
  }
}
