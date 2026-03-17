import 'dart:io' show Platform;

/// Resolves the API base URL at startup.
///
/// ## Environments
///
/// | Environment          | Command                                                                        |
/// |----------------------|--------------------------------------------------------------------------------|
/// | Android emulator     | `flutter run` (default: http://10.0.2.2:8080/api)                            |
/// | iOS simulator        | `flutter run` (default: http://localhost:8080/api)                            |
/// | Physical device (LAN)| `flutter run --dart-define=API_BASE_URL=http://192.168.x.x:8080/api`         |
/// | Staging              | `flutter run --dart-define=API_BASE_URL=https://api-staging.rloco.com/api`   |
/// | Production           | `flutter run --dart-define=API_BASE_URL=https://api.rloco.com/api`           |
/// | Release APK          | `flutter build apk --dart-define=API_BASE_URL=https://api.rloco.com/api`     |
/// | Release IPA          | `flutter build ipa --dart-define=API_BASE_URL=https://api.rloco.com/api`     |
///
/// The production URL **must** be HTTPS.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (fromEnv.isNotEmpty) return fromEnv;
  // Android emulator: 10.0.2.2 maps to the host machine's loopback
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080/api';
  }
  return 'http://localhost:8080/api';
}
