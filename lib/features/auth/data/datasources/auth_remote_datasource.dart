import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../dto/auth_response_dto.dart';
import '../dto/user_dto.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;
  Dio get _dio => _client.dio;

  Future<AuthResponseDto> login(String email, String password) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      // ── 200 OK path ────────────────────────────────────────────────
      final data = response.data;

      if (data == null) {
        throw Exception('Server returned success status but empty response body');
      }

      if (kDebugMode) {
        debugPrint('[AuthRemoteDataSource] Login response: $data');
      }

      // Extract token (handle common naming variations)
      final rawToken = data['token'] ?? data['auth_token'] ?? data['access_token'];
      if (rawToken == null || (rawToken is String && rawToken.isEmpty)) {
        throw Exception('No valid authentication token found in response');
      }

      final token = rawToken is String ? rawToken : rawToken.toString();
      await _client.saveToken(token);

      // Parse DTO — this can also throw if JSON doesn't match
      return AuthResponseDto.fromJson(data);

    } on DioException catch (e) {
      // ── Network / HTTP error handling ──────────────────────────────
      if (kDebugMode) {
        debugPrint('[AuthRemoteDataSource] Login DioException: type=${e.type}, '
            'status=${e.response?.statusCode}, message=${e.message}, '
            'response=${e.response?.data}');
      }
      final statusCode = e.response?.statusCode;
      final serverMessage = e.response?.data?['message'] ?? e.response?.data?['error'];
      final apiEx = getApiException(e);

      String errorMsg;

      // Use ApiException message for connection errors (e.g. "Unable to connect...")
      if (e.response == null && apiEx != null) {
        errorMsg = apiEx.message;
      } else {
        switch (statusCode) {
          case 400:
            errorMsg = serverMessage ?? 'Invalid request (bad credentials or format)';
            break;
          case 401:
            errorMsg = serverMessage ?? 'Invalid email or password';
            break;
          case 403:
            errorMsg = serverMessage ?? 'Account not allowed to login (suspended?)';
            break;
          case 429:
            errorMsg = 'Too many login attempts. Please try again later.';
            break;
          default:
            errorMsg = serverMessage ??
                'Login failed (HTTP $statusCode) — ${e.message}';
        }
      }

      // You can log the full error for debugging
      // In production → use Crashlytics / Sentry / your logging service
      // print('Dio login error: $e\nResponse: ${e.response?.data}');

      throw Exception(errorMsg);
    } on Exception catch (e) {
      throw Exception('Something went wrong during login: ${e.toString()}');
    } catch (e, stackTrace) {
      throw Exception('Unexpected critical error during login: $e');
    }
  }

  Future<AuthResponseDto> register(
      String email, String password, String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password, 'name': name},
    );
    final data = response.data;
    if (data == null) throw Exception('Invalid response');
    final rawToken = data['token'] ?? data['auth_token'];
    final token = rawToken is String ? rawToken : rawToken?.toString();
    if (token != null && token.isNotEmpty) {
      await _client.saveToken(token);
    }
    final dto = AuthResponseDto.fromJson(data);
    return dto;
  }

  Future<void> logout() async {
    await _dio.post<void>('/auth/logout');
    await _client.clearToken();
  }

  Future<UserDto?> getMe() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data;
      if (kDebugMode) debugPrint('[AuthRemoteDataSource] getMe response: $data');
      if (data == null) return null;
      return UserDto.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRemoteDataSource] getMe DioException: status=${e.response?.statusCode}, '
            'data=${e.response?.data}');
      }
      rethrow;
    }
  }

  Future<AuthResponseDto?> refresh() async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/refresh');
    final data = response.data;
    if (data == null) return null;
    final dto = AuthResponseDto.fromJson(data);
    final token = dto.token;
    if (token != null && token.isNotEmpty) {
      await _client.saveToken(token);
    }
    return dto;
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (birthday != null) body['birthday'] = birthday.toIso8601String().split('T').first;
    await _dio.put<void>('/auth/profile', data: body);
  }
}
