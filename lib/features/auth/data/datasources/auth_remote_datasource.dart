import 'dart:io';

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

  Future<void> sendLoginOtp(String phone) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/login-otp/send',
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      // Preserve the server's error code (e.g. USER_NOT_FOUND) so callers can route to signup.
      throw ApiException(
        message: _otpDioMessage(e, 'Could not send verification code'),
        code: getApiException(e)?.code,
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AuthResponseDto> completeLoginOtp(String phone, String code) async {
    return _postAuthExchange(
      {'phone': phone, 'code': code},
      '/auth/login-otp/complete',
    );
  }

  Future<AuthResponseDto> googleSignInWithIdToken(String idToken) async {
    return _postAuthExchange(
      {'id_token': idToken},
      '/auth/google',
    );
  }

  Future<AuthResponseDto> _postAuthExchange(
    Map<String, dynamic> body,
    String path,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw Exception('Server returned success status but empty response body');
      }
      if (kDebugMode) {
        debugPrint('[AuthRemoteDataSource] $path response: $data');
      }
      final rawToken = data['token'] ?? data['auth_token'] ?? data['access_token'];
      if (rawToken == null || (rawToken is String && rawToken.isEmpty)) {
        throw Exception('No valid authentication token found in response');
      }
      final token = rawToken is String ? rawToken : rawToken.toString();
      await _client.saveToken(token);
      return AuthResponseDto.fromJson(data);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthRemoteDataSource] $path DioException: ${e.response?.data}');
      }
      throw Exception(_authExchangeDioMessage(e));
    } on Exception catch (e) {
      throw Exception(e.toString());
    }
  }

  String _otpDioMessage(DioException e, String fallback) {
    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data?['message'] ?? e.response?.data?['error'];
    final apiEx = getApiException(e);
    if (e.response == null && apiEx != null) return apiEx.message;
    if (statusCode == 429) return 'Too many attempts. Please try again later.';
    return serverMessage?.toString() ?? fallback;
  }

  String _authExchangeDioMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = e.response?.data?['message'] ?? e.response?.data?['error'];
    final apiEx = getApiException(e);
    if (e.response == null && apiEx != null) return apiEx.message;
    switch (statusCode) {
      case 400:
        return serverMessage?.toString() ?? 'Invalid request';
      case 401:
        return serverMessage?.toString() ?? 'Authentication failed';
      case 403:
        return serverMessage?.toString() ?? 'Account not allowed';
      case 429:
        return 'Too many attempts. Please try again later.';
      default:
        return serverMessage?.toString() ??
            'Request failed (HTTP ${statusCode ?? '?'})';
    }
  }

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
    } catch (e) {
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
    final hasToken = await _client.getToken();
    if (hasToken == null || hasToken.isEmpty) {
      return null;
    }
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data;
      if (kDebugMode) debugPrint('[AuthRemoteDataSource] getMe response: $data');
      if (data == null) return null;
      return UserDto.fromJson(data);
    } on DioException catch (e) {
      final st = e.response?.statusCode ?? getApiException(e)?.statusCode;
      if (st == 401) {
        if (kDebugMode) {
          debugPrint('[AuthRemoteDataSource] getMe: session invalid (401) — treating as signed out');
        }
        await _client.clearToken();
        return null;
      }
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

  Future<void> sendRegistrationOtp(String phone) async {
    try {
      await _dio.post<Map<String, dynamic>>(
        '/auth/register-otp/send',
        data: {'phone': phone},
      );
    } on DioException catch (e) {
      throw Exception(_otpDioMessage(e, 'Could not send verification code'));
    }
  }

  Future<AuthResponseDto> completeRegistrationOtp({
    required String phone,
    required String code,
    required String email,
    required String password,
    required String name,
  }) async {
    return _postAuthExchange(
      {
        'phone': phone,
        'code': code,
        'email': email,
        'password': password,
        'name': name,
      },
      '/auth/register-otp/complete',
    );
  }

  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    DateTime? birthday,
    String? avatar,
    String? city,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (birthday != null) body['birthday'] = birthday.toIso8601String().split('T').first;
    if (avatar != null) body['avatar'] = avatar;
    if (city != null) body['city'] = city;
    await _dio.put<void>('/auth/profile', data: body);
  }

  Future<String> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: 'avatar.jpg'),
    });
    final response = await _dio.post<Map<String, dynamic>>('/auth/avatar', data: formData);
    final url = response.data?['url'] as String?;
    if (url == null || url.isEmpty) throw Exception('Upload failed: no URL returned');
    return url;
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _dio.put<void>('/auth/password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }

  Future<void> forgotPassword(String email) async {
    await _dio.post<void>('/auth/forgot-password', data: {'email': email});
  }
}
