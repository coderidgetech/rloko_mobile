import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Client-side Stripe must use a publishable key (`pk_…`). Rejects `sk_…` so the app does not crash.
String _clientPublishableOnly(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('sk_')) {
    if (kDebugMode) {
      debugPrint(
        '[Stripe] VITE_STRIPE_PUBLISHABLE_KEY is a secret key (sk_…). '
        'Use the publishable key pk_test_… or pk_live_… from the Stripe Dashboard (Developers → API keys), '
        'same as the web app — never the secret key on mobile.',
      );
    }
    return '';
  }
  if (!t.startsWith('pk_')) {
    if (kDebugMode) {
      debugPrint(
        '[Stripe] VITE_STRIPE_PUBLISHABLE_KEY must start with pk_.',
      );
    }
    return '';
  }
  return t;
}

/// Populated from [loadStripePublishableKeyFromAssets] (raw `assets/env/app.env` parse).
String _stripeFromAppEnvAsset = '';

String? _parseEnvFileValue(String fileContent, String key) {
  for (final raw in fileContent.split('\n')) {
    var line = raw.replaceFirst(RegExp(r'^\ufeff'), '').trimRight();
    final trimmedLeft = line.trimLeft();
    if (trimmedLeft.isEmpty || trimmedLeft.startsWith('#')) continue;
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final k = line.substring(0, eq).trim();
    if (k != key) continue;
    var v = line.substring(eq + 1).trim();
    final inlineComment = v.indexOf(' #');
    if (inlineComment >= 0) {
      v = v.substring(0, inlineComment).trim();
    }
    if (v.length >= 2) {
      if (v.startsWith('"') && v.endsWith('"')) {
        v = v.substring(1, v.length - 1);
      } else if (v.startsWith("'") && v.endsWith("'")) {
        v = v.substring(1, v.length - 1);
      }
    }
    final out = v.trim();
    return out.isEmpty ? null : out;
  }
  return null;
}

/// Call from [main] after [dotenv.load]. Picks up keys dotenv sometimes skips (BOM, quoting).
Future<void> loadStripePublishableKeyFromAssets() async {
  try {
    final raw = await rootBundle.loadString('assets/env/app.env');
    final v = _parseEnvFileValue(raw, 'VITE_STRIPE_PUBLISHABLE_KEY') ??
        _parseEnvFileValue(raw, 'STRIPE_PUBLISHABLE_KEY');
    if (v != null && v.isNotEmpty) {
      _stripeFromAppEnvAsset = v;
    }
  } catch (_) {
    _stripeFromAppEnvAsset = '';
  }
}

/// Same key as web: `VITE_STRIPE_PUBLISHABLE_KEY` in [assets/env/app.env], or compile-time:
/// `--dart-define=VITE_STRIPE_PUBLISHABLE_KEY=pk_test_...` (or `STRIPE_PUBLISHABLE_KEY`).
String get kStripePublishableKey {
  const fromDefine = String.fromEnvironment(
    'VITE_STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  final a = _clientPublishableOnly(fromDefine);
  if (a.isNotEmpty) return a;

  const fromDefineAlt = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  final b = _clientPublishableOnly(fromDefineAlt);
  if (b.isNotEmpty) return b;

  final c = _clientPublishableOnly(_stripeFromAppEnvAsset);
  if (c.isNotEmpty) return c;

  if (!dotenv.isInitialized) {
    return '';
  }
  var d = (dotenv.env['VITE_STRIPE_PUBLISHABLE_KEY'] ?? '').trim();
  if (d.isEmpty) {
    d = (dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '').trim();
  }
  return _clientPublishableOnly(d);
}
