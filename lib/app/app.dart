import 'dart:async';
import 'dart:ui';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakikaki/app/constants/notification.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/service/analytics_service.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';
import 'package:kakikaki/features/diary/domain/model/spelling_feedback_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User, LocalStorage;
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/app/service/auth_service.dart';
import 'package:kakikaki/app/service/diary_feedback_realtime_notification_service.dart';
import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:kakikaki/core/config/config.dart';
import 'package:kakikaki/core/error/error_page.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/permission_request_handler.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/router/routing.dart';
import 'bloc/global_bloc.dart';
import 'domain/entity/user.dart';
import 'constants/constants.dart';
import 'enums/primary_color_type.dart';

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // main.dart에서 await App.initialize() 완료 후 runApp 호출 → GetIt에 GlobalBloc 등록됨
    final bloc = getIt<GlobalBloc>();
    _setupDeepLinkListener(bloc);

    return BlocBuilder<GlobalBloc, GlobalState>(
      bloc: bloc,
      builder: (context, GlobalState state) {
        final primaryColorType = state.primaryColorType.toPrimaryColorType();
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootScaffoldMessengerKey,
          scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {
            PointerDeviceKind.mouse,
            PointerDeviceKind.touch,
            PointerDeviceKind.trackpad,
            PointerDeviceKind.stylus,
            PointerDeviceKind.unknown,
          }),
          theme: Palette().theme(primaryColorType),
          darkTheme: Palette().darkTheme(primaryColorType),
          // 앱 전체를 라이트 테마로 고정
          // themeMode: state.themeModeEnum,
          themeMode: ThemeMode.light,
          locale: state.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, widget) {
            if (Config.enableErrorPage) {
              ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
                try {
                  if (widget is Scaffold ||
                      widget is Navigator ||
                      widget is Router) {
                    return AppErrorPage(errorDetails);
                  }
                  return AppErrorWidget(errorDetails, widget: widget);
                } catch (e, stackTrace) {
                  unawaited(ErrorReporter.report(
                    e,
                    stackTrace: stackTrace,
                    context: 'ErrorWidget.builder fallback',
                  ));
                  return MaterialApp(
                    home: Scaffold(
                      body: Center(
                        child: Text('오류가 발생했습니다: ${errorDetails.exception}'),
                      ),
                    ),
                  );
                }
              };
            }

            if (widget == null) {
              return MaterialApp(
                home: Scaffold(
                  body: Center(
                    child: Text('앱을 초기화하는 중 오류가 발생했습니다.'),
                  ),
                ),
              );
            }
            return widget;
          },
          routerConfig: Routing.router,
        );
      },
    );
  }

  void _setupDeepLinkListener(GlobalBloc bloc) {
    final appLinks = AppLinks();

    appLinks.getInitialLink().then((uri) {
      if (uri != null && _isAuthCallbackUri(uri)) _handleAuthCallback(bloc);
    });

    appLinks.uriLinkStream.listen((uri) {
      if (_isAuthCallbackUri(uri)) _handleAuthCallback(bloc);
    });
  }

  bool _isAuthCallbackUri(Uri uri) =>
      uri.scheme == 'kakikaki' && uri.host == 'auth-callback';

  void _handleAuthCallback(GlobalBloc bloc) {
    AuthService.handleAuthCallback(bloc);
  }

  static WidgetsBinding? _widgetsBinding;
  static bool _isSplashRemoved = false;

  static void preserveSplash({required WidgetsBinding widgetsBinding}) {
    _widgetsBinding = widgetsBinding;
    _widgetsBinding?.deferFirstFrame();
  }

  static Future<void> removeSplash() async {
    if (_isSplashRemoved) return;
    _isSplashRemoved = true;
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      FlutterNativeSplash.remove();
    } finally {
      _widgetsBinding?.allowFirstFrame();
      _widgetsBinding = null;
    }
  }

// 💡 알림 클릭 시 실행될 공통 함수
  static Future<void> _handleNotificationClick(RemoteMessage message) async {
    final type = message.data['type'];
    final diaryId = message.data['diaryId'];

    Log.i('🔔 [푸시 클릭] type: $type, diaryId: $diaryId');

    if (type != null) {
      AnalyticsService.logNotificationOpened(type);

      // 🚨 라우팅 전용 Key인 rootNavigatorKey 사용!
      BuildContext? context = rootNavigatorKey.currentContext;
      int retries = 0;

      // 앱이 막 켜지는 중이라 화면이 없으면 최대 2초까지 0.1초 간격으로 기다려줍니다.
      while (context == null && retries < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        context = rootNavigatorKey.currentContext;
        retries++;
      }

      if (context == null) {
        Log.e('🚨 [푸시 에러] 화면(context)이 준비되지 않아 이동을 취소합니다.');
        return;
      }

      if (type == NotificationConstants.dailyReminder) {
        // context.push('/diary/write');
      } else if (type == NotificationConstants.diaryFeedbackCompleted ||
          type == NotificationConstants.diaryFeedbackFailed) {
        if (diaryId != null) {
          Log.i('🚀 [푸시 라우팅] 일기 상세 정보 조회 시작!');
          _fetchDiaryAndNavigate(context, diaryId);
        }
      }
    }
  }

  // 💡 DB에서 일기를 가져와서 화면으로 쏴주는 함수
  static Future<void> _fetchDiaryAndNavigate(
      BuildContext context, String diaryId) async {
    try {
      Log.i('⏳ [푸시 라우팅] 데이터 fetching 시작...');
      final client = SupabaseUtils.getClientOrNull();
      if (client == null) throw Exception("Supabase client is null");

      // 1. 일기 본문 정보 가져오기
      final diaryData =
          await client.from('diaries').select().eq('id', diaryId).single();

      // 2. 추천 정보 조인해서 가져오기
      final List<dynamic> recData = await client
          .from('user_recommendations')
          .select('*, word:word_id(*), grammar:grammar_id(*)')
          .eq('diary_id', diaryId);

      Log.i('✅ [푸시 라우팅] DB 조회 성공! 객체 조립 시작...');

      // 3. 🚨 [핵심] 수동 객체 생성 (Null 에러 방지)
      final result = DiaryFeedbackResult(
        diaryId: diaryData['id']?.toString() ?? '',
        date: DateTime.tryParse(diaryData['created_at']?.toString() ?? '') ??
            DateTime.now(),
        originalText: diaryData['content']?.toString() ?? '',
        correctedText: diaryData['corrected_content']?.toString() ?? '',
        contentFurigana: diaryData['content_furigana']?.toString() ?? '',
        correctedContentFurigana:
            diaryData['corrected_content_furigana']?.toString() ?? '',
        // 교정 노트 리스트 변환
        spellingFeedback: (diaryData['correction_notes'] as List? ?? [])
            .map((e) =>
                SpellingFeedbackItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        // 추천 리스트 변환 (방금 만든 수동 헬퍼 사용)
        recommendations: recData
            .map((e) => DiaryRecommendationItem.fromJoinedData(
                Map<String, dynamic>.from(e)))
            .toList(),
      );

      Log.i('✅ [푸시 라우팅] 객체 조립 완료! 페이지로 이동합니다.');

      if (context.mounted) {
        // extra로 조립된 result 객체를 통째로 넘깁니다.
        context.push('/diary/feedback?fromHome=true', extra: result);
      }
    } catch (e, stackTrace) {
      Log.e('🚨 [푸시 이동 실패] 에러: $e');
      Log.e('스택 트레이스: $stackTrace');

      // 실패 시 안전하게 홈으로
      if (context.mounted) context.go('/home');
    }
  }

  static Future<void> initialize() async {
    await Config.ensureInitialized();
    await _initializeSupabase();

    // 1. 앱 실행 GA 이벤트 쏘기
    await AnalyticsService.logAppOpen();

    // 2. 포그라운드 푸시 알림 수신 대기
    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   Log.i('포그라운드 푸시 수신: ${message.notification?.title}');
    //   // 앱을 사용 중일 때 푸시가 오면 화면 상단에 직접 토스트/스낵바를 띄워줘야 합니다.
    //   if (message.notification != null) {
    //     rootScaffoldMessengerKey.currentState?.showSnackBar(
    //       SnackBar(content: Text('${message.notification!.title}')),
    //     );
    //   }
    // });

    kakao.KakaoSdk.init(nativeAppKey: Config.kakaoNativeAppKey);

    Bloc.observer = GlobalBlocObserver();

// 1. [앱이 완전히 꺼진 상태]에서 알림을 누르고 들어왔을 때
    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClick(initialMessage);
    }

    // 2. [앱이 백그라운드에 있는 상태]에서 알림을 누르고 들어왔을 때
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationClick);

    await Hive.initFlutter();
    Hive.registerAdapter<GlobalState>(GlobalStateAdapter());
    Hive.registerAdapter<SocialType>(SocialTypeAdapter());
    Hive.registerAdapter<User>(UserAdapter());

    await configureInjection();
    try {
      await getIt.allReady(timeout: const Duration(seconds: 30));
      await PermissionRequestHandler.initFcmTokenRefreshListener();
      final bloc = await getIt.getAsync<GlobalBloc>();
      await AuthService.restoreSessionIfNeeded(bloc);
      DiaryFeedbackRealtimeNotificationService.instance.start(
        messengerKey: rootScaffoldMessengerKey,
      );
    } catch (e, stackTrace) {
      await ErrorReporter.report(
        e,
        stackTrace: stackTrace,
        context: 'App.initialize - getIt.allReady',
      );
      rethrow;
    }
  }

  static Future<void> _initializeSupabase() async {
    if (Config.supabaseUrl.isNotEmpty && Config.supabaseAnonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: Config.supabaseUrl,
          anonKey: Config.supabaseAnonKey,
        );
        SupabaseUtils.isInitialized = true;
        Log.i('Supabase 초기화 완료', name: 'App');
      } catch (e, stackTrace) {
        SupabaseUtils.isInitialized = false;
        await ErrorReporter.report(
          e,
          stackTrace: stackTrace,
          context: 'Supabase 초기화 실패',
        );
      }
    } else {
      SupabaseUtils.isInitialized = false;
      Log.w('Supabase URL 또는 Anon Key가 설정되지 않음', name: 'App');
    }
  }
}
