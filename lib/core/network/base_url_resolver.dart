import 'dart:io' show Platform;

/// Resolves API base URL for the app.
///
/// - Use `--dart-define=API_BASE_URL=http://YOUR_IP:8081/api` to override (e.g. physical device).
/// - Android emulator: default is `http://10.0.2.2:8081/api` (10.0.2.2 = host machine).
/// - iOS simulator / desktop: default is `http://localhost:8081/api`.
/// - Physical device: set API_BASE_URL to your computer's LAN IP (e.g. http://192.168.1.5:8081/api).
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (fromEnv.isNotEmpty) return fromEnv;
  // Android emulator: 10.0.2.2 is the host loopback
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8081/api';
  }
  return 'http://localhost:8081/api';
}
