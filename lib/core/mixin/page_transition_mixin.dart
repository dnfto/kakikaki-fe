import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Fade 전환 효과를 제공하는 Mixin
///
/// 페이지 전환 시 페이드 효과를 적용
/// 사용 예시:
/// ```dart
/// class MyRoute extends GoRouteData with FadeTransitionRouteMixin {
///   @override
///   Page<void> buildPage(BuildContext context, GoRouterState state) {
///     return buildWithFadeTransition(context, MyPage());
///   }
/// }
/// ```
mixin FadeTransitionRouteMixin on GoRouteData {
  /// Fade 전환 효과가 적용된 Page를 생성
  Page<void> buildWithFadeTransition(BuildContext context, Widget child) {
    return CustomTransitionPage<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }
}
