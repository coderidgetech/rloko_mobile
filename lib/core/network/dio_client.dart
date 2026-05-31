import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'network_constants.dart';

const _authTokenKey = 'auth_token';
const _authTokenPrefsKey = 'auth_token_prefs';

/// Provides configured Dio instance and token persistence for mobile.
/// Tokens are stored in FlutterSecureStorage (Keystore/Keychain) with a
/// SharedPreferences fallback for Android emulators where secure storage fails.
class DioClient {
  DioClient({
    FlutterSecureStorage? secureStorage,
    SharedPreferences? sharedPreferences,
  })  : _storage = secureStorage ?? const FlutterSecureStorage(),
        _prefs = sharedPreferences {
    final dio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: Duration(seconds: kTimeoutSeconds),
      receiveTimeout: Duration(seconds: kTimeoutSeconds),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));
    dio.interceptors.addAll([
      _authInterceptor(),
      _errorInterceptor(dio),
    ]);
    _dio = dio;
    // Separate Dio for token refresh — no auth interceptor so the expired
    // Bearer token is not re-attached to the refresh request itself.
    _refreshDio = Dio(BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: Duration(seconds: kTimeoutSeconds),
      receiveTimeout: Duration(seconds: kTimeoutSeconds),
      headers: {'Content-Type': 'application/json'},
    ));
  }

  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefs;
  late final Dio _dio;
  late final Dio _refreshDio;

  Dio get dio => _dio;

  InterceptorsWrapper _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    );
  }

  InterceptorsWrapper _errorInterceptor(Dio dio) {
    return InterceptorsWrapper(
      onError: (error, handler) async {
        final request = error.requestOptions;
        final path = request.path;
        final isAuthMe = path.contains('/auth/me');
        final isLoginOrRegister = path.contains('/auth/login') || path.contains('/auth/register');
        final status = error.response?.statusCode;

        // Don't retry/refresh for login/register - 401 means invalid credentials
        if (status == 401 && !isAuthMe && !isLoginOrRegister) {
          final retry = request.extra['_retry'] as bool? ?? false;
          if (!retry) {
            request.extra['_retry'] = true;
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                final token = await getToken();
                if (token != null) {
                  request.headers['Authorization'] = 'Bearer $token';
                }
                final response = await dio.fetch(request);
                return handler.resolve(response);
              }
            } catch (_) {
              await clearToken();
            }
          }
        }

        if (error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout) {
          return handler.reject(
            DioException(
              requestOptions: request,
              type: error.type,
              error: ApiException(
                message: 'The request took too long. Please try again.',
                statusCode: status,
              ),
              message: kDebugMode ? (error.error?.toString() ?? error.message) : null,
            ),
          );
        }

        if (error.response == null) {
          if (kDebugMode) {
            debugPrint(
              '[DioClient] ${request.uri} failed: type=${error.type} '
              'underlying=${error.error ?? error.message}',
            );
          }
          return handler.reject(
            DioException(
              requestOptions: request,
              type: error.type,
              error: ApiException(
                message: "We couldn't reach the server. Check your internet connection and try again.",
                statusCode: status,
              ),
              message: kDebugMode ? (error.error?.toString() ?? error.message) : null,
            ),
          );
        }

        final data = error.response?.data;
        if (kDebugMode && isLoginOrRegister && status == 401) {
          debugPrint('[DioClient] 401 on $path: data=$data');
        }
        String message = 'Something went wrong. Please try again.';
        if (data is Map) {
          message = (data['message'] ?? data['error'] ?? data['msg'])?.toString() ?? message;
        }
        if (message == 'Something went wrong. Please try again.' && status == 401) {
          message = 'Sign in to continue';
        }
        return handler.reject(
          DioException(
            requestOptions: request,
            response: error.response,
            type: error.type,
            error: ApiException(
              message: message,
              code: data is Map ? data['code']?.toString() : null,
              statusCode: status,
            ),
          ),
        );
      },
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>('/auth/refresh');
      final data = response.data;
      if (data != null && data['token'] != null) {
        await saveToken(data['token'] as String);
        return true;
      }
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> saveToken(String token) async {
    // Write to secure storage first; SharedPreferences is a backup for emulators.
    try {
      await _storage.write(key: _authTokenKey, value: token);
    } catch (e) {
      if (kDebugMode) debugPrint('[DioClient] Secure storage write failed: $e');
    }
    await _prefs?.setString(_authTokenPrefsKey, token);
    if (kDebugMode) debugPrint('[DioClient] Token saved');
  }

  Future<void> clearToken() async {
    try {
      await _storage.delete(key: _authTokenKey);
    } catch (_) {}
    await _prefs?.remove(_authTokenPrefsKey);
  }

  /// Reads token: tries SecureStorage (Keystore/Keychain) first; falls back to
  /// SharedPreferences only on devices where secure storage is unavailable (e.g. some emulators).
  Future<String?> getToken() async {
    // 1. Prefer secure storage on real devices.
    try {
      final token = await _storage.read(key: _authTokenKey);
      if (token != null && token.isNotEmpty) {
        if (kDebugMode && !_tokenLogged) {
          _tokenLogged = true;
          debugPrint('[DioClient] Token found in secure storage');
        }
        return token;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DioClient] Secure storage read failed: $e — trying prefs');
    }
    // 2. Fall back to SharedPreferences (Android emulator / secure storage unavailable).
    final token = _prefs?.getString(_authTokenPrefsKey);
    if (token != null && token.isNotEmpty) {
      if (kDebugMode && !_tokenLogged) {
        _tokenLogged = true;
        debugPrint('[DioClient] Token found in SharedPreferences (emulator fallback)');
      }
      return token;
    }
    if (kDebugMode && !_tokenLogged) {
      _tokenLogged = true;
      debugPrint('[DioClient] No token found - user needs to sign in');
    }
    return null;
  }

  static bool _tokenLogged = false;
}

/// Extension to extract ApiException from DioException.
ApiException? getApiException(Object error) {
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return null;
}
