# Certificate Pinning Plan (S3)

## Status

Planned — not yet implemented.

## Overview

Certificate pinning should be implemented using `HttpClientAdapter` with a custom `SecurityContext` inside the Dio client (`lib/core/network/dio_client.dart`). This prevents man-in-the-middle attacks by ensuring the app only trusts a specific server certificate or public-key hash, rather than any certificate signed by a trusted CA.

## Implementation Plan

### Primary Pin

Pin the leaf certificate (or its public-key SHA-256 hash) for `rloko.com`.

### Backup Pin

A second pin for the intermediate CA certificate must be configured alongside the primary pin. This ensures continuity if the leaf certificate is rotated but the intermediate CA remains the same.

### Rotation Mechanism

A pin rotation mechanism must be in place before implementing pinning in production:

1. The app should fetch an out-of-band pin manifest from a separate, trusted endpoint (or embed a secondary backup pin in the binary) so that a certificate rotation does not lock users out.
2. A server-side grace period of at least 30 days must be maintained during which both the old and new pins are accepted.
3. The app release cycle must be coordinated with the certificate renewal schedule. Let's Encrypt certificates renew every 90 days — plan app releases accordingly.

### Suggested Implementation

```dart
// lib/core/network/dio_client.dart (excerpt)
import 'dart:io';
import 'package:dio/io.dart';

void _applyPinning(Dio dio) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Compare cert.sha256 against pinned hashes.
      // Return false (reject) if the hash does not match any pinned value.
      const pinnedHashes = <String>{
        // Primary leaf pin — replace with real SHA-256 of rloko.com cert public key
        'PLACEHOLDER_PRIMARY_PIN_SHA256',
        // Backup intermediate CA pin
        'PLACEHOLDER_BACKUP_PIN_SHA256',
      };
      return pinnedHashes.contains(_sha256ofDer(cert.der));
    };
    return client;
  };
}
```

### Prerequisites Before Enabling

- [ ] Obtain the current SHA-256 SPKI hash for rloko.com.
- [ ] Obtain the SHA-256 SPKI hash for the intermediate CA.
- [ ] Implement and test the pin-rotation manifest endpoint.
- [ ] Coordinate with the backend/infra team to align the certificate renewal schedule.
- [ ] Test on both Android and iOS physical devices before shipping.

## References

- [OWASP Certificate Pinning Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Pinning_Cheat_Sheet.html)
- [Dio IOHttpClientAdapter](https://pub.dev/packages/dio)
