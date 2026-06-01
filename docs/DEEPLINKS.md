# Deep Link Setup

## Status

Deep links (App Links on Android, Universal Links on iOS) are not yet configured.
The AndroidManifest.xml currently has no `ACTION_VIEW` intent-filter for `https` scheme.

Full deep-link setup requires steps outside this codebase scope (AASA file on the
backend server, Apple Developer Console configuration for iOS). This document tracks
what still needs to be done.

## Android — App Links

Add the following intent-filter inside the `<activity>` tag in
`android/app/src/main/AndroidManifest.xml`, replacing `rloco.app` with your actual
domain:

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="https" android:host="rloco.app" />
</intent-filter>
```

The backend must also serve a Digital Asset Links JSON file at:
`https://rloco.app/.well-known/assetlinks.json`

Example content:
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.rloco.mobile",
    "sha256_cert_fingerprints": ["<YOUR_RELEASE_CERT_SHA256>"]
  }
}]
```

## iOS — Universal Links

1. In Xcode, enable the **Associated Domains** capability and add:
   `applinks:rloco.app`

2. The backend must serve an Apple App Site Association file at:
   `https://rloco.app/.well-known/apple-app-site-association`

Example content:
```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "<TEAM_ID>.<BUNDLE_ID>",
      "paths": ["*"]
    }]
  }
}
```

## Flutter go_router integration

go_router already handles in-app routing. Once the OS-level deep link config above is
complete, incoming URLs will be forwarded to GoRouter automatically — no additional
Flutter code is required.

## Routes eligible for deep linking

| Path | Protected (auth required) |
|------|--------------------------|
| `/product/:id` | No |
| `/category/:gender` | No |
| `/orders/:id` | Yes |
| `/order-confirmation/:id` | Yes |
| `/tracking/:orderId` | Yes |
| `/reviews` | Yes |
