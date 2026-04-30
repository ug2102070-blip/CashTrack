# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt
# You can edit the include path and order by changing the proguardFiles
# directive in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Hive
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }
-keepclassmembers class * extends hive.HiveObject {
    <fields>;
}

# Isar
-keep class isar.** { *; }
-keep @isar.annotation.Collection class *

# Riverpod
-keep class * extends riverpod.** { *; }

# Freezed
-keep class * implements freezed.** { *; }
-keepclassmembers class * {
    @freezed.annotation.* <methods>;
}

# JSON Serialization
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep data models
-keep class com.cashtrack.app.data.models.** { *; }

# Telephony (SMS)
-keep class com.shounakmulay.telephony.** { *; }

# Local Auth
-keep class io.flutter.plugins.localauth.** { *; }

# Prevent obfuscation of classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep setters in Views so that animations can still work
-keepclassmembers public class * extends android.view.View {
    void set*(***);
    *** get*();
}

# Keep classes for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses