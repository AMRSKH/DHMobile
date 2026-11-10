# Keep Flutter/JNI bridge classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class dev.flutter.** { *; }

# Keep Dart-generated plugin registrant
-keep class io.flutter.** { *; }

# Keep VLC player native bridge (flutter_vlc_player + libvlc)
-keep class org.videolan.** { *; }
-keep class io.flutter.plugins.videoplayer.** { *; }

# Keep our volume MethodChannel handler
-keep class dev.amscenter.donghua_player.MainActivity { *; }
-keep class dhmobile.amscenter.dev.MainActivity { *; }

# Keep serializable model data (Hive + JSON)
-keep class **.model.** { *; }
-keep class **.models.** { *; }

# Gson/R8: keep annotation
-keepattributes *Annotation*, InnerClasses, EnclosingMethod, Signature, RuntimeVisibleAnnotations

-dontwarn org.videolan.**
-dontwarn kotlin.**
-dontwarn org.intellij.lang.annotations.**

# Encryption / bytecopy compatibility
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.feature.**
-keep class com.google.android.play.core.** { *; }