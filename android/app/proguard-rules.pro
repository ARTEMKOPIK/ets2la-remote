# Flutter core: the Flutter tool already ships a consumer rules file that
# keeps engine classes, plugin registrants, and reflection entry points.
# Everything here is app-specific on top of that.

# Keep our Application, Activity, receivers and services — they're referenced
# from AndroidManifest.xml by name, so R8 wouldn't otherwise prove they're
# reachable.
-keep class com.ets2la.ets2la_remote.MainActivity { *; }
-keep class com.ets2la.ets2la_remote.AutopilotWidgetProvider { *; }
-keep class com.ets2la.ets2la_remote.KeepAliveService { *; }
-keep class com.ets2la.ets2la_remote.WearMessageListenerService { *; }

# Wearable Data Layer (com.google.android.gms:play-services-wearable) uses
# reflection to look up callback signatures — keep its listener interface.
-keep class com.google.android.gms.wearable.** { *; }
-dontwarn com.google.android.gms.wearable.**

# flutter_inappwebview registers annotation-based method channels via
# kotlin reflection; stripping its bridge names breaks the WebView.
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }

# Kotlin runtime / coroutines — harmless but quiets stray warnings.
-dontwarn kotlinx.coroutines.**
-keepclassmembers class ** {
    @kotlinx.coroutines.InternalCoroutinesApi *;
}
