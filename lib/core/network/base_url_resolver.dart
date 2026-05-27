import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String _normalizeApiBase(String url) {
  var s = url.trim();
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s;
}

/// Resolves the API base URL (e.g. `https://dev.rloko.com/api` — same as web [VITE_API_URL]).
///
/// Priority: `--dart-define=API_BASE_URL=...` → [assets/env/app.env] `API_BASE_URL` or
/// `VITE_API_URL` (same as frontend) → Android emulator / iOS simulator localhost defaults.
///
/// Note: [https://dev.rloko.com/api] (no path after `/api`) may 404; the app calls
/// `/config`, `/auth/...`, etc. Test with `GET .../api/config` or `GET .../health`.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (fromEnv.isNotEmpty) {
    return _normalizeApiBase(fromEnv);
  }
  if (dotenv.isInitialized) {
    final fromFile = (dotenv.env['API_BASE_URL'] ?? dotenv.env['VITE_API_URL'] ?? '')
        .trim();
    if (fromFile.isNotEmpty) {
      return _normalizeApiBase(fromFile);
    }
  }
  if (kReleaseMode) {
    throw StateError(
      'API_BASE_URL is required in release builds. '
      'Pass --dart-define=API_BASE_URL=https://your-host/api (and keep secrets out of git).',
    );
  }
  // Debug/profile: local backend on host when no URL is configured.
  debugPrint(
    '[API] No API_BASE_URL: using local emulator default. '
    'Set assets/env/app.env or --dart-define=API_BASE_URL=... for a remote API.',
  );
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8080/api';
  }
  return 'http://localhost:8080/api';
}
