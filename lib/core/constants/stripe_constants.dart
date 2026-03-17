/// Stripe publishable key injected at build time.
///
/// Provide via:
///   flutter run  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
///   flutter build apk --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...
///   flutter build ipa --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_...
const String kStripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: '',
);
