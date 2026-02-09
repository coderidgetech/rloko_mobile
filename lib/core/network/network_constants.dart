import 'base_url_resolver.dart';

/// Base URL for the API. Resolved at runtime so Android emulator can use 10.0.2.2.
/// Override with: flutter run --dart-define=API_BASE_URL=http://YOUR_IP:8081/api
String get kBaseUrl => resolveApiBaseUrl();

const int kTimeoutSeconds = 30;
