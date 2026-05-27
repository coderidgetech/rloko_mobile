// Generated from google-services.json (Android) and GoogleService-Info.plist (iOS).
// To regenerate run: flutterfire configure
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Web push uses the Firebase JS SDK via VITE_FIREBASE_* env vars.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios; // reuse iOS config for macOS simulator builds
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Source: android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDIc59N3eyTkPgVP6jbk0RZJRlfSJu1Db0',
    appId: '1:350870700467:android:9d421eb42ac7e02bb54bc6',
    messagingSenderId: '350870700467',
    projectId: 'rloko-bc8e5',
    storageBucket: 'rloko-bc8e5.firebasestorage.app',
  );

  // Source: ios/Runner/GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC94cuhxghEP6QW9AzlRd0Tzn_Jai0VWww',
    appId: '1:350870700467:ios:a030b260a9e45846b54bc6',
    messagingSenderId: '350870700467',
    projectId: 'rloko-bc8e5',
    storageBucket: 'rloko-bc8e5.firebasestorage.app',
    iosBundleId: 'com.coderidge.rloko',
  );
}
