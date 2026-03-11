import 'dart:ui';

import 'package:kakikaki/app/constants/palette.dart';

/// Color 관련 유틸
extension ColorX on Color {
  // ───────────────────────────────────────── 기존 메서드 ─────────────────────────────────────────
  /// 새 권장 방식 – 0.0~1.0
  Color withExactOpacity(double opacity) =>
      withValues(alpha: opacity.clamp(0.0, 1.0));

  /// 8-bit 알파를 그대로 주고 싶을 때 사용
  Color withExactAlpha8(int alpha8) =>
      withValues(alpha: (alpha8.clamp(0, 255) / 255.0));

  /// R/G/B를 8-bit 정수로 바꾸고 싶을 때 사용
  Color withRed8(int r8) => withValues(red: (r8.clamp(0, 255) / 255.0));
  Color withGreen8(int g8) => withValues(green: (g8.clamp(0, 255) / 255.0));
  Color withBlue8(int b8) => withValues(blue: (b8.clamp(0, 255) / 255.0));

  // 기존 API와 이름만 동일 (레거시가 많은 코드일 경우 브릿지)
  @Deprecated('Use withExactOpacity')
  Color withExactOpacitySafe(double opacity) => withExactOpacity(opacity);

  // ───────────────────────────────────────── 새로 추가 ─────────────────────────────────────────
  /// 흰색을 섞어 밝기를 높인다.
  ///
  /// * [ratio] 0.0 ⇒ 원본색, 1.0 ⇒ 완전 흰색(= `Color(0xFFFFFFFF)`)
  /// * 내부적으로 `Color.lerp`(linear-interpolate) 사용
  Color mixWithWhite(double ratio) =>
      Color.lerp(this, Palette.white, ratio.clamp(0.0, 1.0))!;

  /// 다른 색과 섞는다.
  ///
  /// * [other] 섞을 대상 색상
  /// * [ratio] 0.0 ⇒ 원본색(this), 1.0 ⇒ 다른 색(other), 0.5 ⇒ 두 색의 중간
  /// * 내부적으로 `Color.lerp`(linear-interpolate) 사용
  Color mixWith(Color other, double ratio) =>
      Color.lerp(this, other, ratio.clamp(0.0, 1.0))!;
}

/* 사용 예시
final c1 = context.palette.primary.withExactOpacity(0.25); // 25 %
final c2 = Colors.red.withExactAlpha8(153);                // 0x99 ≒ 60 %
final c3 = myColor.withRed8(200).withExactOpacity(0.8);
final c4 = myColor.mixWithWhite(0.3);                      // 30 % 화이트 믹스
final c5 = Colors.red.mixWith(Colors.blue, 0.5);          // 빨강과 파랑을 50:50으로 섞기
*/
