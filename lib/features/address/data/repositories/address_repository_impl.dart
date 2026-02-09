import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/entities/address_entity.dart';
import '../../domain/repositories/address_repository.dart';
import '../datasources/address_remote_datasource.dart';
import '../dto/address_dto.dart';

class AddressRepositoryImpl implements AddressRepository {
  AddressRepositoryImpl(this._dataSource);

  final AddressRemoteDataSource _dataSource;

  @override
  Future<List<AddressEntity>> list() async {
    try {
      final list = await _dataSource.list();
      return list.map((e) => e.toEntity()).toList();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<AddressEntity> getById(String id) async {
    try {
      final dto = await _dataSource.getById(id);
      return dto.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<AddressEntity> create(AddressEntity address) async {
    try {
      final dto = _entityToDto(address);
      final created = await _dataSource.create(dto);
      return created.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<AddressEntity> update(String id, AddressEntity address) async {
    try {
      final dto = _entityToDto(address);
      final updated = await _dataSource.update(id, dto);
      return updated.toEntity();
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dataSource.delete(id);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> setDefault(String id) async {
    try {
      await _dataSource.setDefault(id);
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  AddressDto _entityToDto(AddressEntity e) => AddressDto(
        id: e.id,
        userId: e.userId,
        name: e.name,
        type: e.type,
        addressLine: e.addressLine,
        addressLine2: e.addressLine2,
        city: e.city,
        state: e.state,
        pincode: e.pincode,
        mobile: e.mobile,
        country: e.country,
        isDefault: e.isDefault,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );
}
