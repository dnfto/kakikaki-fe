import 'package:flutter/material.dart';
import 'package:kakikaki/app/enums/primary_color_type.dart';

/// 다크 / 라이트 모드 지원 (Blue 테마로 통합)
/// Hive 데이터베이스에 저장해 관리
class Palette {
  /// Primary 색상 타입에 따라 동적으로 테마 생성 (라이트 모드)
  ThemeData theme([PrimaryColorType? primaryColorType]) {
    final colorType = primaryColorType ?? PrimaryColorType.skyBlue;
    return createThemeData(_getColorScheme(colorType));
  }

  /// Primary 색상 타입에 따라 동적으로 다크 테마 생성
  ThemeData darkTheme([PrimaryColorType? primaryColorType]) {
    final colorType = primaryColorType ?? PrimaryColorType.skyBlue;
    return createThemeData(_getDarkColorScheme(colorType));
  }

  /// Primary 색상 타입에 따라 ColorScheme 반환 (라이트 모드)
  ColorScheme _getColorScheme(PrimaryColorType colorType) {
    final primary = getPrimaryColor(colorType);
    return ColorScheme.light(
      primary: primary,
      onPrimary: Palette.white,
      error: Palette.red50,
      onError: Palette.white,
      errorContainer: Palette.red10,
      onErrorContainer: Palette.red90,
      surface: Palette.white,
      onSurface: Palette.black,
      surfaceContainer: Palette.gray10,
      surfaceContainerHigh: Palette.gray20,
      surfaceContainerHighest: Palette.gray30,
      shadow: Palette.gray20,
      outline: Palette.gray40,
      outlineVariant: Palette.gray60,
      inverseSurface: Palette.gray80,
      onInverseSurface: Palette.white,
      surfaceTint: primary,
    );
  }

  /// Primary 색상 타입에 따라 ColorScheme 반환 (다크 모드)
  ColorScheme _getDarkColorScheme(PrimaryColorType colorType) {
    final primary = getPrimaryColor(colorType);
    return ColorScheme.dark(
      primary: primary,
      onPrimary: Palette.white,
      error: Palette.red50,
      onError: Palette.white,
      errorContainer: Palette.red90,
      onErrorContainer: Palette.red10,
      surface: Palette.gray80,
      onSurface: Palette.gray10,
      surfaceContainer: Palette.gray70,
      surfaceContainerHigh: Palette.gray60,
      surfaceContainerHighest: Palette.gray50,
      shadow: Palette.black,
      outline: Palette.gray50,
      outlineVariant: Palette.gray40,
      inverseSurface: Palette.gray10,
      onInverseSurface: Palette.gray90,
      surfaceTint: primary,
    );
  }

  /// Primary 색상 타입에 따라 primary 색상 반환
  static Color getPrimaryColor(PrimaryColorType colorType) {
    switch (colorType) {
      case PrimaryColorType.skyBlue:
        return Palette.skyBlue50;
      case PrimaryColorType.pink:
        return Palette.pink50;
      case PrimaryColorType.blue:
        return Palette.blue50;
      case PrimaryColorType.red:
        return Palette.red50;
      case PrimaryColorType.orange:
        return Palette.orange50;
    }
  }

  /// Primary 색상 타입에 따라 다양한 농도의 색상 반환
  static Color getPrimaryColorWithOpacity(
    PrimaryColorType colorType,
    int opacity, // 10, 30, 40, 50, 60, 80
  ) {
    switch (colorType) {
      case PrimaryColorType.skyBlue:
        switch (opacity) {
          case 10:
            return Palette.skyBlue30;
          case 30:
            return Palette.skyBlue40;
          case 40:
            return Palette.skyBlue50;
          case 50:
            return Palette.skyBlue60;
          case 60:
            return Palette.skyBlue80;
          case 80:
            return Palette.skyBlue80;
          default:
            return Palette.skyBlue60;
        }
      case PrimaryColorType.pink:
        switch (opacity) {
          case 10:
            return Palette.pink30;
          case 30:
            return Palette.pink40;
          case 40:
            return Palette.pink50;
          case 50:
            return Palette.pink60;
          case 60:
            return Palette.pink80;
          case 80:
            return Palette.pink80;
          default:
            return Palette.pink60;
        }
      case PrimaryColorType.blue:
        switch (opacity) {
          case 10:
            return Palette.blue10;
          case 30:
            return Palette.blue30;
          case 40:
            return Palette.blue40;
          case 50:
            return Palette.blue50;
          case 60:
            return Palette.blue60;
          case 80:
            return Palette.blue80;
          default:
            return Palette.blue50;
        }
      case PrimaryColorType.red:
        switch (opacity) {
          case 10:
            return Palette.red10;
          case 30:
            return Palette.red30;
          case 40:
            return Palette.red40;
          case 50:
            return Palette.red50;
          case 60:
            return Palette.red60;
          case 80:
            return Palette.red80;
          default:
            return Palette.red50;
        }
      case PrimaryColorType.orange:
        switch (opacity) {
          case 10:
            return Palette.orange10;
          case 30:
            return Palette.orange30;
          case 40:
            return Palette.orange40;
          case 50:
            return Palette.orange50;
          case 60:
            return Palette.orange60;
          case 80:
            return Palette.orange80;
          default:
            return Palette.orange50;
        }
    }
  }

  // Pink Colors (기존 핑크 팔레트 — 핑크 톤이 필요할 때)
  static const Color pink50 = Color.fromARGB(255, 231, 174, 176);
  static const Color pink80 = Color(0xFFC98A8D);
  static const Color pink60 = Color(0xFFD9A1A4);
  static const Color pink40 = Color(0xFFE8B8BA);
  static const Color pink30 = Color(0xFFF1D4D5);
  static const Color pink10 = Color(0xFFF9EAEB);

  // Sky Blue (기본 테마 primary — #A9C7E2)
  static const Color skyBlue50 = Color(0xFFA9C7E2);
  static const Color skyBlue80 = Color(0xFF7A9FC4);
  static const Color skyBlue60 = Color(0xFF94B8D0);
  static const Color skyBlue40 = Color(0xFFB7D0E8);
  static const Color skyBlue30 = Color(0xFFC5D9ED);
  static const Color skyBlue10 = Color(0xFFE8F2FA);

  // Blue Colors
  static const Color blue50 = Color(0xFF0077FF);
  static const Color blue80 = Color(0xFF0059CC);
  static const Color blue60 = Color(0xFF0066E6);
  static const Color blue40 = Color(0xFF3385FF);
  static const Color blue30 = Color(0xFF66A3FF);
  static const Color blue10 = Color(0xFFE6F2FF);

  // Red Colors
  static const Color red50 = Color(0xFFF92C25);
  static const Color red80 = Color(0xFFC7221D);
  static const Color red60 = Color(0xFFE6251F);
  static const Color red40 = Color(0xFFFB5A54);
  static const Color red30 = Color(0xFFFC8D88);
  static const Color red10 = Color(0xFFFEE3D3);
  static const Color red90 = Color(0xFF770729);

  // Orange Colors (주황색)
  static const Color orange50 = Color(0xFFFF6815); // accentColor
  static const Color orange80 = Color(0xFFCC5311);
  static const Color orange60 = Color(0xFFE65A13);
  static const Color orange40 = Color(0xFFFF8A4D);
  static const Color orange30 = Color(0xFFFFA880);
  static const Color orange10 = Color(0xFFFFE5D9);

  // Yellow Colors (노란색 - 주황색과 함께 사용)
  static const Color yellow50 = Color(0xFFFFC021); // subYellowColor
  static const Color yellow80 = Color(0xFFCC9A1A);
  static const Color yellow60 = Color(0xFFE6B01E);
  static const Color yellow40 = Color(0xFFFFCD4D);
  static const Color yellow30 = Color(0xFFFFDA7A);
  static const Color yellow10 = Color(0xFFFFF5D9);

  // Gray Scale
  static const Color gray90 = Color(0xFF000000);
  static const Color gray80 = Color(0xFF2B2B2B);
  static const Color gray70 = Color(0xFF4C4C4C);
  static const Color gray60 = Color(0xFF6E6E6E);
  static const Color gray50 = Color(0xFF72787F); // main
  static const Color gray = gray50;
  static const Color gray40 = Color(0xFF8F8F8F);
  static const Color gray30 = Color(0xFFB1AFAF);
  static const Color gray20 = Color(0xFFD1D1D1);
  static const Color gray10 = Color(0xFFF2F2F2);
  static const Color white = Color(0xFFFFFFFF);
  // static const Color black = Color(0xFF1A1A1A);
  static const Color black = Color(0xFF1A1B1D);

  static const Color subBlueColor = blue50;
  static const Color subLimeColor = Color(0xFFCBEE4C);
  static const Color accentColor = orange50; // 주황색
  static const Color subYellowColor = yellow50; // 노란색
}

// 테마 데이터 팩토리
ThemeData createThemeData(ColorScheme colorScheme) {
  // 기본 TextTheme 정의
  TextTheme baseTextTheme =
      Typography.material2018(platform: TargetPlatform.android).black.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface);

  return ThemeData(
    colorScheme: colorScheme,
    useMaterial3: true, // Material 3 디자인 사용
    // TextTheme 커스터마이징
    textTheme: baseTextTheme.copyWith(
      // 보조 텍스트 스타일 설정 (예: bodyMedium)
      bodyMedium:
          baseTextTheme.bodyMedium?.copyWith(color: Palette.gray50), // 회색 적용
    ),
  );
}
