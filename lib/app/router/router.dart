import 'dart:convert';

import 'package:kakikaki/core/mixin/page_transition_mixin.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/model/diary_write_payload.dart';
import 'package:kakikaki/features/home/presentation/page/home_page.dart';
import 'package:kakikaki/features/my/presentation/page/my_page.dart';
import 'package:kakikaki/features/my/presentation/page/language_settings_page.dart';
import 'package:kakikaki/features/my/presentation/page/calendar_settings_page.dart';
import 'package:kakikaki/features/my/presentation/page/color_settings_page.dart';
import 'package:kakikaki/features/my/presentation/page/inquiry_page.dart';
import 'package:kakikaki/features/my/presentation/page/inquiry_list_page.dart';
import 'package:kakikaki/features/my/presentation/page/open_source_license_page.dart';
import 'package:kakikaki/features/my/presentation/page/withdrawal_reason_page.dart';
import 'package:kakikaki/features/diary/presentation/page/diary_list_page.dart';

import 'package:kakikaki/features/diary/presentation/page/diary_feedback_page.dart';
import 'package:kakikaki/features/diary/presentation/page/diary_processing_page.dart';
import 'package:kakikaki/features/diary/presentation/page/diary_write_page.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/presentation/page/vocabulary_list_page.dart';
import 'package:kakikaki/features/vocabulary/presentation/page/vocabulary_detail_page.dart';
import 'package:kakikaki/features/study/presentation/page/study_page.dart';
import 'package:kakikaki/features/auth/presentation/page/sign_in_page.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// 이전 화면으로 돌아가기
void pop(BuildContext context, [Object? extra]) =>
    Navigator.of(context).pop(extra);

/// 네비게이션 메서드
enum NavigationMethod { push, replace, go, pushReplacement }

/// 라우트 네비게이션 헬퍼 함수
Future<T?> navigate<T>(
  BuildContext context, {
  required String path,
  NavigationMethod method = NavigationMethod.push,
  Object? extra,
  VoidCallback? callback,
}) async {
  final goRouter = GoRouter.of(context);

  Log.d('이동 - 라우트: $path / 메서드: $method');

  T? result;
  switch (method) {
    case NavigationMethod.push:
      result = await goRouter.push<T>(path, extra: extra);
      break;
    case NavigationMethod.replace:
      result = await goRouter.replace<T>(path, extra: extra);
      break;
    case NavigationMethod.go:
      goRouter.go(path, extra: extra);
      break;
    case NavigationMethod.pushReplacement:
      result = await goRouter.pushReplacement<T>(path, extra: extra);
      break;
  }

  callback?.call();
  return result;
}

@TypedGoRoute<InitialRoute>(path: '/')
class InitialRoute extends GoRouteData with FadeTransitionRouteMixin {
  const InitialRoute();

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    // GlobalBloc의 isLoggedIn 상태만 확인 (세션 복원은 App.initialize()에서 완료됨)
    final globalBloc = getIt<GlobalBloc>();
    final isLoggedIn = globalBloc.state.isLoggedIn;

    if (!isLoggedIn) {
      return '/sign-in';
    }
    return '/home';
  }
}

/// 로그인 페이지 라우트
@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with FadeTransitionRouteMixin {
  const SignInRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const SignInPage());
  }
}

/// 홈 페이지 라우트
@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData with FadeTransitionRouteMixin {
  const HomeRoute();

  @override
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    // GlobalBloc의 isLoggedIn 상태만 확인 (세션 복원은 App.initialize()에서 완료됨)
    final globalBloc = getIt<GlobalBloc>();
    final isLoggedIn = globalBloc.state.isLoggedIn;

    Log.d('HomeRoute redirect - isLoggedIn=$isLoggedIn');

    if (!isLoggedIn) {
      return '/sign-in';
    }
    return null;
  }

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const HomePage());
  }
}

/// 단어장 리스트 라우트
@TypedGoRoute<VocabularyRoute>(path: '/vocabulary')
class VocabularyRoute extends GoRouteData with FadeTransitionRouteMixin {
  const VocabularyRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const VocabularyListPage());
  }
}

/// 단어 상세 라우트
@TypedGoRoute<VocabularyDetailRoute>(path: '/vocabulary/:id')
class VocabularyDetailRoute extends GoRouteData with FadeTransitionRouteMixin {
  const VocabularyDetailRoute({required this.id, this.type = 'word'});

  final int id;
  final String type; // 쿼리 파라미터는 String으로 받음

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // 문자열을 Enum으로 변환하여 전달
    final vocabularyType = VocabularyType.fromString(type);

    return buildWithFadeTransition(
      context,
      VocabularyDetailPage(id: id, type: vocabularyType),
    );
  }
}

/// 피드 페이지 라우트
@TypedGoRoute<StudyRoute>(path: '/study')
class StudyRoute extends GoRouteData with FadeTransitionRouteMixin {
  const StudyRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const StudyPage());
  }
}

/// 마이페이지 라우트
@TypedGoRoute<MyPageRoute>(path: '/my')
class MyPageRoute extends GoRouteData with FadeTransitionRouteMixin {
  const MyPageRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // GlobalBloc을 GetIt에서 가져와서 제공
    final globalBloc = getIt<GlobalBloc>();
    final child = BlocProvider<GlobalBloc>.value(
      value: globalBloc,
      child: const MyPage(),
    );
    return buildWithFadeTransition(context, child);
  }
}

/// 언어 설정 페이지 라우트
@TypedGoRoute<LanguageSettingsRoute>(path: '/my/language-settings')
class LanguageSettingsRoute extends GoRouteData with FadeTransitionRouteMixin {
  const LanguageSettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // GlobalBloc을 GetIt에서 가져와서 제공
    final globalBloc = getIt<GlobalBloc>();
    final child = BlocProvider<GlobalBloc>.value(
      value: globalBloc,
      child: const LanguageSettingsPage(),
    );
    return buildWithFadeTransition(context, child);
  }
}

/// 캘린더 설정 페이지 라우트
@TypedGoRoute<CalendarSettingsRoute>(path: '/my/calendar-settings')
class CalendarSettingsRoute extends GoRouteData with FadeTransitionRouteMixin {
  const CalendarSettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const CalendarSettingsPage());
  }
}

/// 색상 설정 페이지 라우트
@TypedGoRoute<ColorSettingsRoute>(path: '/my/color-settings')
class ColorSettingsRoute extends GoRouteData with FadeTransitionRouteMixin {
  const ColorSettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    // GlobalBloc을 GetIt에서 가져와서 제공
    final globalBloc = getIt<GlobalBloc>();
    final child = BlocProvider<GlobalBloc>.value(
      value: globalBloc,
      child: const ColorSettingsPage(),
    );
    return buildWithFadeTransition(context, child);
  }
}

/// 내가 쓴 일기 목록 페이지 라우트
@TypedGoRoute<DiaryListRoute>(path: '/my/diaries')
class DiaryListRoute extends GoRouteData with FadeTransitionRouteMixin {
  const DiaryListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const DiaryListPage());
  }
}

/// 문의 내역 리스트 페이지 라우트
@TypedGoRoute<InquiryListRoute>(path: '/my/inquiry')
class InquiryListRoute extends GoRouteData with FadeTransitionRouteMixin {
  const InquiryListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const InquiryListPage());
  }
}

/// 문의 작성 페이지 라우트
@TypedGoRoute<InquiryNewRoute>(path: '/my/inquiry/new')
class InquiryNewRoute extends GoRouteData with FadeTransitionRouteMixin {
  const InquiryNewRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const InquiryPage());
  }
}

/// 오픈소스 라이선스 페이지 라우트
@TypedGoRoute<OpenSourceLicenseRoute>(path: '/my/open-source-license')
class OpenSourceLicenseRoute extends GoRouteData with FadeTransitionRouteMixin {
  const OpenSourceLicenseRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return buildWithFadeTransition(context, const OpenSourceLicensePage());
  }
}

/// 회원 탈퇴 (사유 선택) 페이지 라우트
@TypedGoRoute<WithdrawalReasonRoute>(path: '/my/withdrawal')
class WithdrawalReasonRoute extends GoRouteData with FadeTransitionRouteMixin {
  const WithdrawalReasonRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final globalBloc = getIt<GlobalBloc>();
    return buildWithFadeTransition(
      context,
      BlocProvider<GlobalBloc>.value(
        value: globalBloc,
        child: const WithdrawalReasonPage(),
      ),
    );
  }
}

@TypedGoRoute<DiaryWriteRoute>(path: '/diary/write')
class DiaryWriteRoute extends GoRouteData with FadeTransitionRouteMixin {
  const DiaryWriteRoute({
    required this.dateMillis,
    this.topic = '',
    this.topicKo = '',
    this.initialContent = '',
    this.diaryId,
  });

  final int dateMillis;
  final String topic;
  final String topicKo; // 한국어 주제
  final String initialContent;
  final String? diaryId; // 수정 시에만 값이 있음

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final date = DateTime.fromMillisecondsSinceEpoch(dateMillis);
    return buildWithFadeTransition(
      context,
      DiaryWritePage(
        initialDate: date,
        initialTopic: topic,
        initialTopicKo: topicKo,
        initialContent: initialContent,
        diaryId: diaryId,
      ),
    );
  }
}

@TypedGoRoute<DiaryProcessingRoute>(path: '/diary/processing')
class DiaryProcessingRoute extends GoRouteData with FadeTransitionRouteMixin {
  const DiaryProcessingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final extra = state.extra;
    if (extra is! String) {
      return buildWithFadeTransition(
        context,
        const _InvalidRoutePage(message: '일기 작성 정보가 없어요.'),
      );
    }
    DiaryWritePayload payload;
    try {
      final decoded = jsonDecode(extra) as Map<String, dynamic>;
      payload = DiaryWritePayload.fromJson(decoded);
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'DiaryProcessingRoute invalid payload',
      );
      return buildWithFadeTransition(
        context,
        const _InvalidRoutePage(message: '일기 작성 정보 형식이 올바르지 않아요.'),
      );
    }
    return buildWithFadeTransition(
      context,
      DiaryProcessingPage(payload: payload),
    );
  }
}

@TypedGoRoute<DiaryFeedbackRoute>(path: '/diary/feedback')
class DiaryFeedbackRoute extends GoRouteData with FadeTransitionRouteMixin {
  const DiaryFeedbackRoute({this.fromHome = false});

  final bool fromHome;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    final extra = state.extra;
    DiaryFeedbackResult? result;
    if (extra is DiaryFeedbackResult) {
      result = extra;
    } else if (extra is String) {
      try {
        final decoded = jsonDecode(extra) as Map<String, dynamic>;
        result = DiaryFeedbackResult.fromJson(decoded);
      } catch (e, stackTrace) {
        ErrorReporter.ignoreExpected(
          e,
          stackTrace: stackTrace,
          context: 'DiaryFeedbackRoute invalid payload',
        );
        return buildWithFadeTransition(
          context,
          const _InvalidRoutePage(message: '피드백 데이터 형식이 올바르지 않아요.'),
        );
      }
    }
    // 쿼리 파라미터에서 fromHome 파싱 (TypedGoRoute가 자동 파싱하지 않을 수 있음)
    final fromHomeParam = state.uri.queryParameters['fromHome'];
    final isFromHome = fromHomeParam == 'true' || fromHome;
    return buildWithFadeTransition(
      context,
      _DiaryFeedbackRouteContainer(
        initialResult: result,
        fromHome: isFromHome,
      ),
    );
  }
}

class _DiaryFeedbackRouteContainer extends StatefulWidget {
  const _DiaryFeedbackRouteContainer({
    required this.initialResult,
    required this.fromHome,
  });

  final DiaryFeedbackResult? initialResult;
  final bool fromHome;

  @override
  State<_DiaryFeedbackRouteContainer> createState() =>
      _DiaryFeedbackRouteContainerState();
}

class _DiaryFeedbackRouteContainerState
    extends State<_DiaryFeedbackRouteContainer> {
  DiaryFeedbackResult? _cachedResult;

  @override
  void initState() {
    super.initState();
    _cachedResult = widget.initialResult;
  }

  @override
  void didUpdateWidget(covariant _DiaryFeedbackRouteContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialResult != null) {
      _cachedResult = widget.initialResult;
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _cachedResult;
    if (result == null) {
      return _InvalidRoutePage(
          message: context.l10n.router_diary_feedback_missing);
    }
    return DiaryFeedbackPage(result: result, fromHome: widget.fromHome);
  }
}

class _InvalidRoutePage extends StatelessWidget {
  const _InvalidRoutePage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(message),
      ),
    );
  }
}
