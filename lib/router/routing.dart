import 'dart:async';

import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/service/analytics_service.dart';
import 'package:kakikaki/core/error/error_route_page.dart';
import 'package:kakikaki/core/config/config.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 앱의 라우팅 설정
///
/// * 사용자가 있을 경우 리다이렉트
/// * 공유 토큰이 있을 경우 리다이렉트
class Routing {
  const Routing._();

  static GoRouter router = GoRouter(
    refreshListenable: GoRouterRefreshStream(getIt<GlobalBloc>().stream),
    debugLogDiagnostics: Config.enableNavigatorObserverLog,
    observers: [GoRouterObserver(), AnalyticsService.observer],
    navigatorKey: rootNavigatorKey,
    initialLocation: InitialRoute().location,
    routes: $appRoutes,
    errorBuilder: (context, GoRouterState state) => ErrorRoutePage(state),

    // 1. async 키워드 제거! (화면 전환 시 딜레이 방지)
    redirect: (context, state) {
      final currentPath = state.uri.toString();
      final isAuthRoute = currentPath.startsWith('/auth');

      if (currentPath == '/') {
        return null; // InitialRoute에서 처리
      }

      if (isAuthRoute) {
        return null;
      }

      // 앱 초기화 때 세팅된 GlobalBloc의 상태
      final isLoggedIn = getIt<GlobalBloc>().state.isLoggedIn;

      // [핵심 수정] 로그인된 유저가 로그인 화면에 접근하면 홈으로 자동 이동!
      if (isLoggedIn && currentPath.startsWith('/sign-in')) {
        Log.d('이미 로그인된 상태입니다. 홈으로 자동 이동합니다.');
        return '/home';
      }

      // 비로그인 상태 보호
      if (!isLoggedIn) {
        final allowAnonymousPrefixes = [
          '/force-update',
          '/onboarding',
          '/sign-in'
        ];
        final isException =
            allowAnonymousPrefixes.any((p) => currentPath.startsWith(p));

        if (!isException) {
          Log.d('비로그인 상태에서 보호된 페이지 접근. 로그인 페이지로 리다이렉트');
          return '/sign-in';
        }
      }

      return null;
    },
  );
}

/// 네비게이터 관찰자 클래스
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // 새로운 라우트가 푸시될 때 호출되는 메서드
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
