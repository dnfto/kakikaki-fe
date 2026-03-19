import 'package:kakikaki/app/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 앱의 텍스트 스타일, 폰트, 스케일 등을 커스텀하는 설정
///
/// 모든 텍스트 스타일은 Noto Sans KR 폰트로 통일
/// Google Fonts 라이브러리를 사용하여 폰트를 로드
///
/// 참고: Google Fonts에는 Pretendard가 없으므로, 유사한 스타일의 Noto Sans KR을 사용
/// Pretendard를 사용하려면 asset 폰트를 사용하거나, 다른 폰트로 변경할 수 있습니다.
///
/// 디자이너 제공 스펙:
/// - H2: 28px / 125% / -1% (700, 600, 500, 400)
/// - H3: 24px / 130% / -1% (700, 600, 500, 400)
/// - H4: 20px / 140% / -1% (700, 600, 500, 400)
/// - H5: 18px / 150% / -2% (700, 600, 500, 400)
/// - H6: 16px / 150% / -2% (700, 600, 500, 400)
/// - H7: 14px / 150% / -2% (700, 600, 500, 400)
/// - H8: 12px / 150% / -3% (600, 500, 400)
/// - H9: 10px / 150% / -2% (600, 500)
class Fonts {
  const Fonts._();

  /// Noto Sans KR 폰트를 Google Fonts를 통해 로드
  ///
  /// Google Fonts에는 Pretendard가 없으므로, 유사한 스타일의 Noto Sans KR을 사용
  /// Pretendard를 사용하려면 asset 폰트를 사용하거나, 다른 폰트로 변경할 수 있습니다.
  static TextStyle _pretendardTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    required double letterSpacing,
  }) {
    return GoogleFonts.notoSansKr(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: Palette.gray90,
    );
  }

  // --- H2 스타일 (28px / 125% / -1%) ---
  static TextStyle h2_700 = _pretendardTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 28 * -0.01,
  );

  static TextStyle h2_600 = _pretendardTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 28 * -0.01,
  );

  static TextStyle h2_500 = _pretendardTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 28 * -0.01,
  );

  static TextStyle h2_400 = _pretendardTextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: 28 * -0.01,
  );

  // --- H3 스타일 (24px / 130% / -1%) ---
  static TextStyle h3_700 = _pretendardTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.30,
    letterSpacing: 24 * -0.01,
  );

  static TextStyle h3_600 = _pretendardTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.30,
    letterSpacing: 24 * -0.01,
  );

  static TextStyle h3_500 = _pretendardTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.30,
    letterSpacing: 24 * -0.01,
  );

  static TextStyle h3_400 = _pretendardTextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    height: 1.30,
    letterSpacing: 24 * -0.01,
  );

  // --- H4 스타일 (20px / 140% / -1%) ---
  static TextStyle h4_700 = _pretendardTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.40,
    letterSpacing: 20 * -0.01,
  );

  static TextStyle h4_600 = _pretendardTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.40,
    letterSpacing: 20 * -0.01,
  );

  static TextStyle h4_500 = _pretendardTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.40,
    letterSpacing: 20 * -0.01,
  );

  static TextStyle h4_400 = _pretendardTextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.40,
    letterSpacing: 20 * -0.01,
  );

  // --- H5 스타일 (18px / 150% / -2%) ---
  static TextStyle h5_700 = _pretendardTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.50,
    letterSpacing: 18 * -0.02,
  );

  static TextStyle h5_600 = _pretendardTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 18 * -0.02,
  );

  static TextStyle h5_500 = _pretendardTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 18 * -0.02,
  );

  static TextStyle h5_400 = _pretendardTextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 18 * -0.02,
  );

  // --- H6 스타일 (16px / 150% / -2%) ---
  static TextStyle h6_700 = _pretendardTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.50,
    letterSpacing: 16 * -0.02,
  );

  static TextStyle h6_600 = _pretendardTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 16 * -0.02,
  );

  static TextStyle h6_500 = _pretendardTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 16 * -0.02,
  );

  static TextStyle h6_400 = _pretendardTextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 16 * -0.02,
  );

  // --- H7 스타일 (14px / 150% / -2%) ---
  static TextStyle h7_700 = _pretendardTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.50,
    letterSpacing: 14 * -0.02,
  );

  static TextStyle h7_600 = _pretendardTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 14 * -0.02,
  );

  static TextStyle h7_500 = _pretendardTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 14 * -0.02,
  );

  static TextStyle h7_400 = _pretendardTextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 14 * -0.02,
  );

  // --- H8 스타일 (12px / 150% / -3%) ---
  static TextStyle h8_600 = _pretendardTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 12 * -0.03,
  );

  static TextStyle h8_500 = _pretendardTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 12 * -0.03,
  );

  static TextStyle h8_400 = _pretendardTextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 12 * -0.03,
  );

  // --- H9 스타일 (10px / 150% / -2%) ---
  static TextStyle h9_600 = _pretendardTextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.50,
    letterSpacing: 10 * -0.02,
  );

  static TextStyle h9_500 = _pretendardTextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 10 * -0.02,
  );
}
