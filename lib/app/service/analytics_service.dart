import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // GoRouter에 연결할 옵저버 (화면 이동 자동 추적)
  static FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// 1. 앱 최초 실행 로깅
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
  }

  /// 2. 커스텀 이벤트: 소셜 로그인 성공
  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// 3. 구체적인 커스텀 이벤트 예시: 글 작성 완료
  static Future<void> logDiaryCreated({
    required String diaryId,
    required int textLength,
  }) async {
    await _analytics.logEvent(
      name: 'diary_created',
      parameters: {
        'diary_id': diaryId,
        'text_length': textLength, // 이런 구체적인 데이터도 넘길 수 있음!
      },
    );
  }

  /// 푸시 알림 클릭(오픈) 추적
  static Future<void> logNotificationOpened(String type) async {
    await _analytics.logEvent(
      name: 'notification_opened',
      parameters: {
        'notification_type': type,
      },
    );
    Log.i("GA 로그: 알림 클릭됨 ($type)");
  }
}
