import 'base_url_resolver.dart';

/// Base URL for the API. Set `API_BASE_URL` in `assets/env/app.env` (or `--dart-define=API_BASE_URL=...`).
String get kBaseUrl => resolveApiBaseUrl();

const int kTimeoutSeconds = 30;
