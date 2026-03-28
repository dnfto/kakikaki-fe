import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:kakikaki/core/config/config.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kakikaki/firebase_options.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // TODO: 여기서 로컬 DB(Hive)에 알림을 저장하거나 뱃지 카운트를 올릴 수 있습니다.
}

void main() async {
  await _initializeWithSentry();
}

Future<void> _initializeWithSentry() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Config 전에 Firebase 먼저 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await Config.ensureInitialized();
  ErrorReporter.installGlobalHandlers();

  // 앱 버전 정보 가져오기
  final packageInfo = await PackageInfo.fromPlatform();
  final appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

  if (Config.enableSentry && Config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = Config.sentryDsn;
        options.environment = Config.isDevFlavor ? 'development' : 'production';
        options.tracesSampleRate = 1.0; // 샘플링 비율 (1.0 = 100% 전송)
        options.debug = kDebugMode; // 디버그 모드에서는 Sentry 비활성화
        options.release = '${Config.appName}@$appVersion';
        options.dist = packageInfo.buildNumber; // 빌드 번호
        options.enableAutoPerformanceTracing = true; // 성능 모니터링
        options.enableAutoSessionTracking = true; // 브레드크럼 자동 수집

        options.attachStacktrace = true; // 모든 이벤트에 스택 트레이스 첨부
        options.enableNdkScopeSync = true; // NDK 스코프 동기화
        options.anrEnabled = true; // ANR (Application Not Responding) 감지
      },
      appRunner: () => _runApp(),
    );
  } else {
    await _runApp(); // Sentry 없이 앱 실행
  }
}

Future<void> _runApp() async {
  final binding = WidgetsBinding.instance;
  App.preserveSplash(widgetsBinding: binding);

  // 릴리즈 모드에서 생명주기 관리
  if (kReleaseMode) {
    binding.addObserver(
      LifecycleEventHandler(
        detachedCallBack: () async {
          Log.i('앱이 백그라운드로 이동');
        },
        resumedCallBack: () async {
          Log.i('앱이 포그라운드로 복귀');
        },
      ),
    );
  }

  try {
    await App.initialize();

    // 앱 초기화 완료 후 스플래시 제거
    await App.removeSplash();
  } catch (e, stackTrace) {
    await ErrorReporter.report(
      e,
      stackTrace: stackTrace,
      context: '앱 초기화 실패',
    );

    // 에러 발생 시에도 스플래시 제거
    await App.removeSplash();
  }

  runApp(const App());
}

/// 앱 생명주기 이벤트 핸들러
class LifecycleEventHandler extends WidgetsBindingObserver {
  final Future<void> Function()? detachedCallBack;
  final Future<void> Function()? resumedCallBack;

  LifecycleEventHandler({
    this.detachedCallBack,
    this.resumedCallBack,
  });

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.detached:
        await detachedCallBack?.call();
        break;
      case AppLifecycleState.resumed:
        await resumedCallBack?.call();
        break;
      default:
        break;
    }
  }
}
