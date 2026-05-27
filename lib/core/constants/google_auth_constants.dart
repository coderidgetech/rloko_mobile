import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Web OAuth client ID — same as backend [GOOGLE_CLIENT_ID] and web [VITE_GOOGLE_CLIENT_ID].
/// Used as [GoogleSignIn] `serverClientId` so the plugin can return an `id_token` for [POST /auth/google].
///
/// Set via either:
/// - `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=...apps.googleusercontent.com`
/// - or `GOOGLE_WEB_CLIENT_ID=...` in [assets/env/app.env] (loaded at startup)
String resolveGoogleWebClientId() {
  const fromDefine = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
  final trimmed = fromDefine.trim();
  if (trimmed.isNotEmpty) return trimmed;
  return (dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '').trim();
}

/// iOS (and macOS) **application** OAuth client from Google Cloud (type *iOS*, bundle id must match).
/// Pass as [GoogleSignIn] `clientId` on Apple platforms. Optional if you configure `Info.plist` instead
/// ([GIDClientID] / URL schemes) — we prefer Dart for one place to set values.
///
/// - `--dart-define=GOOGLE_IOS_CLIENT_ID=...apps.googleusercontent.com`
/// - or `GOOGLE_IOS_CLIENT_ID` in [assets/env/app.env]
String resolveGoogleIosClientId() {
  const fromDefine = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');
  if (fromDefine.isNotEmpty) return fromDefine.trim();
  return (dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '').trim();
}
