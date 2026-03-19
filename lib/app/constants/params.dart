import 'package:flutter/widgets.dart';

/// 앱의 애니메이션, 호스트, 웹에 대한 설정 파라미터
class Params {
  const Params._();

  /// 애니메이션 곡선
  static const Curve animationCurve = Curves.fastOutSlowIn;

  /// 애니메이션 지속 시간
  static const Duration animationDuration = Duration(milliseconds: 400);

  /// 빠른 애니메이션 지속 시간
  static const Duration animationDurationFast = Duration(milliseconds: 200);

  /// 느린 애니메이션 지속 시간
  static const Duration animationDurationLow = Duration(milliseconds: 800);

  /// 입력 종료 후 지연 시간
  static const Duration delayInputEnd = Duration(milliseconds: 1000);
}
