# ============================================================
# ProGuard / R8 rules — HablaVas
# R8 (release) borraba clases de OneSignal y Google Sign-In que
# hacen falta en runtime -> la app se cerraba al abrir el APK
# release (en debug no pasa porque no minifica).
# ============================================================

# ---------- OneSignal (push) ----------
-keep class com.onesignal.** { *; }
-dontwarn com.onesignal.**
-keepclassmembers class com.onesignal.** { *; }

# ---------- Google Sign-In ----------
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-dontwarn com.google.android.gms.**

# ---------- Firebase (viene con OneSignal y Sign-In) ----------
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ---------- Google Play Services (base) ----------
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# ---------- Flutter / plugins no deben tocarse ----------
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
