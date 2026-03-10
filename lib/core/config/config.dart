import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'dart:io';

/// 앱의 설정 값들을 중앙에서 관리하는 클래스
///
/// 개발, 테스트, 운영 환경에 따라 다른 값을 적용합니다.
abstract class Config {
  static bool _isInitialized = false;

  /// 일반 로그 출력 여부
  static const enableGeneralLog = kDebugMode;

  /// JSON 로그를 보기 좋게 출력할지 여부
  static const isPrettyJson = kDebugMode;

  /// 빌드 시점에 환경 변수로 읽는 FLAVOR (--dart-define=FLAVOR=dev or --dart-define=FLAVOR=prod)
  static const flavor = String.fromEnvironment('FLAVOR');

  /// 개발 환경 여부
  static bool get isDevFlavor => flavor.toLowerCase().contains('dev');

  /// 프로덕션 환경 여부
  static bool get isProdFlavor => flavor.toLowerCase().contains('prod');

  /// Native 플랫폼에서 flavor 정보를 가져오는 MethodChannel
  static const _platform = MethodChannel('io.kakikaki/meta');

  /// 네이티브 플랫폼에서 flavor 정보 가져오기
  static Future<String> getNativeFlavor() async {
    try {
      final result = await _platform.invokeMethod<String>('getFlavor') ?? 'dev';
      return result;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'Config.getNativeFlavor',
      );
      return 'dev';
    }
  }

  /// 네트워크 기본 URL (--dart-define=URL=https://api.example.com)
  static const baseUrl = String.fromEnvironment('URL');

  /// 네트워크 요청 타임아웃 (안드로이드: 45초, iOS: 20초)
  static Duration get timeout {
    if (Platform.isAndroid) {
      return const Duration(seconds: 45);
    }
    return const Duration(seconds: 20);
  }

  /// 네트워크 요청 실패 시 재시도 횟수
  static const maxRetries = 1;

  /// BLoC Observer 로그 설정
  static const logOnBlocChange = false;
  static const logOnBlocCreate = false;
  static const logOnBlocClose = false;
  static const logOnBlocError = kDebugMode;
  static const logOnBlocEvent = kDebugMode;
  static const logOnBlocTransition = false;

  /// Navigator Observer 설정
  static const enableErrorPage = kReleaseMode;
  static const enableNavigatorObserverLog = kDebugMode;

  /// 네트워크 로그 설정
  static const enableLogNetworkException = kDebugMode;
  static const enableLogRequestInfo = kDebugMode;

  /// 딥링크 URL (--dart-define=DEEP_LINK_URL=https://example.com)
  static const deepLinkUrl = String.fromEnvironment('DEEP_LINK_URL');

  /// 알림 로그 출력 여부
  static const enableNotificationLog = kDebugMode;

  /// 소셜 로그인 설정
  static String get kakaoNativeAppKey =>
      dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

  /// Sentry 설정
  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static const enableSentry = kReleaseMode;

  /// Sentry release 식별자에 사용할 앱 이름
  static const String appName = 'kakikaki';

  /// Supabase 설정
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// 초기화 메서드 (중복 호출 방지)
  static Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await initialize();
  }

  /// 환경 변수 초기화
  ///
  /// 빌드 예시:
  /// - 개발: flutter run --dart-define=FLAVOR=dev --dart-define=URL=https://dev.api.com
  /// - 프로덕션: flutter run --release --dart-define=FLAVOR=prod --dart-define=URL=https://api.com
  static Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    try {
      // Flavor 결정 (우선순위: dart-define FLAVOR > native flavor > default dev)
      String flavorToUse = flavor;

      // dart-define FLAVOR가 없으면 native platform에서 가져오기
      if (flavor.isEmpty) {
        Log.i('dart-define FLAVOR가 없음, native platform에서 flavor 감지 중...',
            name: 'Config');
        flavorToUse = await getNativeFlavor();
        Log.i('Native flavor 감지: $flavorToUse', name: 'Config');
      }

      // FLAVOR에 따라 동적으로 env 파일 선택
      final envFileName =
          flavorToUse.toLowerCase().contains('prod') ? 'prod.env' : 'dev.env';
      Log.i('로딩할 환경 파일: $envFileName (FLAVOR: $flavorToUse)', name: 'Config');
      await dotenv.load(fileName: envFileName);
      Log.i('dotenv 로딩 완료', name: 'Config');
      _isInitialized = true;
    } catch (e, s) {
      await ErrorReporter.report(
        e,
        stackTrace: s,
        context: 'Config.initialize dotenv',
      );
      Log.e('dotenv 로딩 실패', name: 'Config', errorObject: e, stackTrace: s);
    }
  }
}
