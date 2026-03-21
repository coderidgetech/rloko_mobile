import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource, this._dioClient);

  final AuthRemoteDataSource _dataSource;
  final DioClient _dioClient;

  @override
  Future<AuthResult> login(String email, String password) async {
    try {
      final dto = await _dataSource.login(email, password);
      return AuthResult(
        user: dto.user.toEntity(),
        token: dto.token,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<AuthResult> register(String email, String password, String name) async {
    try {
      final dto = await _dataSource.register(email, password, name);
      return AuthResult(
        user: dto.user.toEntity(),
        token: dto.token,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _dataSource.logout();
    } on DioException catch (e) {
      await _dioClient.clearToken();
      throw getApiException(e) ?? e;
    }
  }

  @override
  Future<UserEntity?> getMe() async {
    try {
      final dto = await _dataSource.getMe();
      return dto?.toEntity();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _dioClient.clearToken();
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AuthResult?> refresh() async {
    try {
      final dto = await _dataSource.refresh();
      return dto != null
          ? AuthResult(user: dto.user.toEntity(), token: dto.token)
          : null;
    } on DioException catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
  }) async {
    try {
      await _dataSource.updateProfile(
        name: name,
        email: email,
        phone: phone,
        birthday: birthday,
      );
    } on DioException catch (e) {
      throw getApiException(e) ?? e;
    }
  }
}
