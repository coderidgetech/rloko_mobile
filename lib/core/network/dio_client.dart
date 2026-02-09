import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_exception.dart';
import 'network_constants.dart';

const _authTokenKey = 'auth_token';
const _authTokenPrefsKey = 'auth_token_prefs';

/// Provides configured Dio instance and token persistence for mobile.
/// Persists token in both secure storage and SharedPreferences so session
/// survives even when FlutterSecureStorage fails (e.g. some Android emulators).
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
  }

  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefs;
  late final Dio _dio;

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
              error: ApiException(
                message: 'The request took too long. Please try again.',
                statusCode: status,
              ),
            ),
          );
        }

        if (error.response == null) {
          final base = request.baseUrl;
          return handler.reject(
            DioException(
              requestOptions: request,
              error: ApiException(
                message:
                    'Unable to connect to $base. Ensure the backend is running and on the same Wi‑Fi. '
                    'On a physical device, run: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8081/api',
                statusCode: status,
              ),
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
      final response = await _dio.post<Map<String, dynamic>>('/auth/refresh');
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
    if (_prefs != null) await _prefs!.setString(_authTokenPrefsKey, token);
    try {
      await _storage.write(key: _authTokenKey, value: token);
    } catch (e) {
      if (kDebugMode) debugPrint('[DioClient] Secure storage write failed: $e (token saved to prefs)');
    }
    if (kDebugMode) debugPrint('[DioClient] Token saved (session will persist across app restarts)');
  }

  Future<void> clearToken() async {
    if (_prefs != null) await _prefs!.remove(_authTokenPrefsKey);
    try {
      await _storage.delete(key: _authTokenKey);
    } catch (_) {}
  }

  /// Reads token: tries SharedPreferences first (reliable on emulators), then secure storage.
  /// FlutterSecureStorage can fail on some Android emulators, so prefs is preferred for reads.
  Future<String?> getToken() async {
    // 1. Try SharedPreferences first - most reliable on Android emulator
    var token = _prefs?.getString(_authTokenPrefsKey);
    if (token != null && token.isNotEmpty) {
      if (kDebugMode && !_tokenLogged) {
        _tokenLogged = true;
        debugPrint('[DioClient] Token found in SharedPreferences (session restored)');
      }
      return token;
    }
    // 2. Fall back to secure storage (wrap in try-catch - can throw on some emulators)
    try {
      token = await _storage.read(key: _authTokenKey);
      if (token != null && token.isNotEmpty) {
        if (_prefs != null) await _prefs!.setString(_authTokenPrefsKey, token);
        if (kDebugMode && !_tokenLogged) {
          _tokenLogged = true;
          debugPrint('[DioClient] Token found in secure storage (session restored)');
        }
        return token;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[DioClient] Secure storage read failed: $e');
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
