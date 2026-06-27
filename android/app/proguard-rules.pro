# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Stripe Android SDK
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Keep model classes used by Gson / JSON serialisation
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# OkHttp / Retrofit (used by Stripe SDK internally)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Flutter references Play Core (deferred components / split installs) which this app
# does not use. Without these, R8 fails the release build with "Missing class
# com.google.android.play.core.*". Silence + keep so minify completes.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
