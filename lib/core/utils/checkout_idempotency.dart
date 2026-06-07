import 'dart:math';

/// Generates an Idempotency-Key for `POST /orders`, mirroring web's
/// `checkoutIdempotencyKey()`. The caller holds a single key for the duration
/// of one checkout attempt and reuses it across retries (network failure, tap
/// again) so the backend dedupes instead of creating duplicate orders. A fresh
/// key is generated only for a brand-new checkout attempt.
String generateIdempotencyKey() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  // RFC 4122 v4: set version (0100) and variant (10) bits.
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String seg(int start, int end) => bytes
      .sublist(start, end)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${seg(0, 4)}-${seg(4, 6)}-${seg(6, 8)}-${seg(8, 10)}-${seg(10, 16)}';
}
