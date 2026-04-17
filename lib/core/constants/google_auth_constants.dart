/// Web OAuth client ID (same as `VITE_GOOGLE_CLIENT_ID` / backend `GOOGLE_CLIENT_ID`).
/// Pass at build time: `--dart-define=GOOGLE_WEB_CLIENT_ID=xxx.apps.googleusercontent.com`
/// Required for `id_token` on Android when exchanging with `/auth/google`.
const String kGoogleWebClientId = String.fromEnvironment(
  'GOOGLE_WEB_CLIENT_ID',
  defaultValue: '',
);
