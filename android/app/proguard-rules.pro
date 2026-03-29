# Flutter 기본 규칙
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Dart VM
-keep class io.flutter.embedding.engine.dart.DartMessenger { *; }
-keep class io.flutter.plugin.common.** { *; }

# Hive 관련 규칙
-keep class * extends com.hivedb.** { *; }
-keep class * implements com.hivedb.** { *; }
-keepclassmembers class * extends com.hivedb.** { *; }
-keep @com.hivedb.** class * { *; }
-keep class hive_flutter.** { *; }

# Freezed 생성 클래스 보호
-keep class **$*.class { *; }
-keep class **.freezed.dart { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# BLoC 관련 규칙
-keep class * extends androidx.lifecycle.ViewModel { *; }
-keep class * extends androidx.lifecycle.AndroidViewModel { *; }

# Gson 관련 규칙 (JSON 직렬화/역직렬화)
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Injectable & GetIt (의존성 주입)
-keep class * {
    @javax.inject.* *;
    @injectable.* *;
}
-keepclassmembers class * {
    @javax.inject.* *;
    @injectable.* *;
}

# 리플렉션 보호
-keepattributes InnerClasses
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# Dart 생성 모델 클래스 보호 (Freezed, json_serializable)
-keep class * implements com.google.gson.JsonSerializer { *; }
-keep class * implements com.google.gson.JsonDeserializer { *; }
-keep class * extends java.lang.Enum { *; }

# Firebase 관련
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Kakao SDK
-keep class com.kakao.sdk.** { *; }
-keep class com.kakao.** { *; }
-dontwarn com.kakao.**

# Google Sign In
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# OkHttp & Retrofit (네트워크 통신)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Kotlin Coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# 일반적인 앱 모델 보호 (프로젝트의 모든 data 클래스)
# TODO: 앱의 패키지명으로 변경
-keep class com.example.app.** { *; }
-keepclassmembers class com.example.app.** { *; }
-keepclasseswithmembers class com.example.app.** { *; }

# 모든 Kotlin 데이터 클래스 보호
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

# 모든 애노테이션 클래스 보호
-keep @interface * { *; }
-keep class * {
    @com.google.gson.annotations.SerializedName <fields>;
    @androidx.annotation.Keep <fields>;
    @androidx.annotation.Keep <methods>;
}

# Reflection 사용하는 모든 클래스 보호
-keepclassmembers class * {
    public <init>(...);
}

# 이미지 처리 라이브러리
-keep class androidx.exifinterface.** { *; }

# 위치 정보
-keep class com.google.android.gms.location.** { *; }

# 지도
-keep class com.google.android.gms.maps.** { *; }

# WebView
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebChromeClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# 비디오 플레이어
-keep class com.google.android.exoplayer2.** { *; }

# 디버깅을 위한 라인 번호 및 소스 파일명 유지
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Sentry 관련 규칙
-keepattributes LineNumberTable,SourceFile
-dontwarn org.slf4j.**
-dontwarn io.sentry.**
-keep class io.sentry.** { *; }
-keep interface io.sentry.** { *; }

# Google Play Core (Flutter deferred components - 실제 사용하지 않을 수 있음)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# 일반적인 경고 무시
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

