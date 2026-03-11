import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// BuildContext에 다양한 유틸리티 메서드를 추가
extension ContextExtension on BuildContext {
  /// 다국어 반환
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// 앱 테마 및 색 반환
  ThemeData get theme => Theme.of(this);

  /// [PaletteData.of(context).appColors]과 유사
  ColorScheme get palette => theme.colorScheme;

  /// 사용자 정의 테마 반환
  /// (레거시) 기존 코드 호환을 위해 유지합니다.
  /// 실제 앱 테마는 `Theme.of(context)`를 사용해야 동적 테마 변경이 반영됩니다.
  ThemeData get appTheme => theme;

  /// 가장 가까운 MediaQuery 조상의 platformBrightness를 반환하거나, 부모 조상이(ancestor) 존재하지 않는 경우 [Brightness.light]를 반환
  Brightness get platformBrightness => MediaQuery.platformBrightnessOf(this);

  /// 주어진 컨텍스트를 둘러싼 이 클래스의 가장 가까운 인스턴스의 상태를 반환
  ScaffoldMessengerState get messenger => ScaffoldMessenger.of(this);

  /// mediaQuerySize: 화면의 전체 크기를 반환
  // 가장 가까운 MediaQuery 조상의 크기를 반환하거나, 조상이 존재하지 않는 경우 예외를 발생시킨다.
  Size get mediaQuerySize => MediaQuery.sizeOf(this);

  /// 화면 너비 반환
  double get screenWidth => mediaQuerySize.width;

  /// 화면 높이 반환
  double get screenHeight => mediaQuerySize.height;

  /// mediaQueryViewPadding: 안전 영역 패딩(e.g. notch)을 반환
  // 가장 가까운 MediaQuery 조상의 viewPadding을 반환하거나, 조상이 존재하지 않는 경우 예외를 발생시킨다.
  EdgeInsets get mediaQueryViewPadding => MediaQuery.viewPaddingOf(this);

  /// mediaQueryViewInsets: 키보드가 나타났을 때 화면 패딩을 반환
  // 가장 가까운 MediaQuery 조상의 viewInsets을 반환하거나, 조상이 존재하지 않는 경우 예외를 발생시킨다.
  EdgeInsets get mediaQueryViewInsets => MediaQuery.viewInsetsOf(this);

  /// mediaQueryOrientation: 가로 또는 세로 방향을 반환
  // 가장 가까운 MediaQuery 조상의 방향성을 반환하거나, 조상이 존재하지 않는 경우 예외를 발생시킨다.
  Orientation get mediaQueryOrientation => MediaQuery.orientationOf(this);

  /// [Theme.of(context).colorScheme]과 유사
  ColorScheme get colorScheme => theme.colorScheme;

  /// [Theme.of(context).textStyle]과 유사
  TextTheme get textStyle => theme.textTheme;

  /// 현재 테마가 다크모드인지 판별
  /// [Theme.of(context).brightness]를 확인하여 다크모드 여부를 반환합니다.
  bool get isDarkMode => theme.brightness == Brightness.dark;

  /// 현재 테마가 라이트모드인지 판별
  /// [Theme.of(context).brightness]를 확인하여 라이트모드 여부를 반환합니다.
  bool get isLightMode => theme.brightness == Brightness.light;

  // /// [PaletteData.of(context).themeMode]과 유사
  // ThemeMode? get themeMode => appTheme.themeMode;

  // /// [PaletteData.of(context).locale]과 유사
  // Locale? get locale => appTheme.locale;

  /// 화면의 shortestSide를 반환
  double get mediaQueryShortestSide => mediaQuerySize.shortestSide;

  /// 기기가 가로 모드(Landscape mode) 모드인지 확인
  bool get isLandscape => mediaQueryOrientation == Orientation.landscape;

  /// 기기가 세로 모드(portrait mode)인지 검사
  bool get isPortrait => mediaQueryOrientation == Orientation.portrait;

  /// 화면의 가로와 세로 중 더 짧은 쪽의 길이가 600p보다 작은 경우 true 반환
  bool get isPhone => mediaQueryShortestSide < 600;

  /// 화면의 가로와 세로 중 더 짧은 쪽의 길이가 600p 이상인 경우 true 반환
  bool get isSmallTablet => mediaQueryShortestSide >= 600;

  /// 화면의 가로와 세로 중 더 짧은 쪽의 길이가 720p 이상인 경우 true 반환
  bool get isLargeTablet => mediaQueryShortestSide >= 720;

  /// 기기가 태블릿인지 검사
  bool get isTablet => isSmallTablet || isLargeTablet;

  /// 화면 크기에 따라 특정 값을 반환하는 반응형 유틸리티
  /// 모바일/태블릿/데스크톱에서 각각 다른 UI를 적용할 수 있다.
  /// 기기 너비가 1200 이상인 경우 [desktop] 값을 반환한다.
  /// 기기 너비가 600 이상이고 1200 미만인 경우 [tablet] 값을 반환한다.
  /// 기기 너비가 300 미만인 경우 [watch] 값을 반환한다.
  /// 그 외의 경우 [mobile] 값을 반환한다.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? watch,
  }) {
    final double deviceWidth = mediaQueryShortestSide;

    if (deviceWidth >= 1200 && desktop != null) {
      return desktop;
    } else if (deviceWidth >= 600 && tablet != null) {
      return tablet;
    } else if (deviceWidth < 300 && watch != null) {
      return watch;
    } else {
      return mobile;
    }
  }

  /// 태블릿/데스크톱에서 콘텐츠 최대 너비 (가독성·레이아웃 유지)
  static const double _contentMaxWidth = 600;

  /// 태블릿/데스크톱에서 사용할 콘텐츠 너비 (화면보다 크면 maxWidth 적용)
  double get constrainedContentWidth {
    if (!isTablet) return screenWidth;
    return screenWidth > _contentMaxWidth ? _contentMaxWidth : screenWidth;
  }

  /// 반응형 수평 마진 (태블릿에서는 상한 적용)
  double get responsiveHorizontalMargin {
    final base = screenWidth * 0.05;
    return isTablet ? base.clamp(16, 48) : base;
  }

  /// 반응형 수직 마진
  double get responsiveVerticalMargin {
    final base = screenHeight * 0.02;
    return isTablet ? base.clamp(12, 32) : base;
  }

  /// 다이얼로그/모달용 최대 너비 (태블릿에서 과도한 확대 방지)
  double get dialogMaxWidth =>
      isTablet ? (screenWidth * 0.9).clamp(320, 500) : screenWidth * 0.9;
}

// `Silver`: CustomScrollView에서 스크롤 가능한 리스트나 레이아웃을 만들기 위해 사용하는 하위 위젯
// `SliverToBoxAdapter`: 단일 위젯을 Sliver에 포함시킬 때 사용
// 일반 `Widget은` 직접 `CustomScrollView`에 추가할 수 없지만,
// `SliverToBoxAdapter`를 사용하면 일반 `Widget`도 `CustomScrollView`에 포함될 수 있다.
extension WidgetExtension on Widget {
  SliverToBoxAdapter get toSliverBox => SliverToBoxAdapter(child: this);

  SliverPadding toSliverPadding(EdgeInsetsGeometry padding) => SliverPadding(
        padding: padding,
        sliver: toSliverBox,
      );
}

extension LocaleExtension on BuildContext {
  bool get isKorean => Localizations.localeOf(this).languageCode == 'ko';
  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';
}

extension TextStyleHelper on BuildContext {
  // --- H2 스타일 (28px / 125% / -1%) ---
  TextStyle get h2_700Style => Fonts.h2_700;
  TextStyle get h2_600Style => Fonts.h2_600;
  TextStyle get h2_500Style => Fonts.h2_500;
  TextStyle get h2_400Style => Fonts.h2_400;

  // --- H3 스타일 (24px / 130% / -1%) ---
  TextStyle get h3_700Style => Fonts.h3_700;
  TextStyle get h3_600Style => Fonts.h3_600;
  TextStyle get h3_500Style => Fonts.h3_500;
  TextStyle get h3_400Style => Fonts.h3_400;

  // --- H4 스타일 (20px / 140% / -1%) ---
  TextStyle get h4_700Style => Fonts.h4_700;
  TextStyle get h4_600Style => Fonts.h4_600;
  TextStyle get h4_500Style => Fonts.h4_500;
  TextStyle get h4_400Style => Fonts.h4_400;

  // --- H5 스타일 (18px / 150% / -2%) ---
  TextStyle get h5_700Style => Fonts.h5_700;
  TextStyle get h5_600Style => Fonts.h5_600;
  TextStyle get h5_500Style => Fonts.h5_500;
  TextStyle get h5_400Style => Fonts.h5_400;

  // --- H6 스타일 (16px / 150% / -2%) ---
  TextStyle get h6_700Style => Fonts.h6_700;
  TextStyle get h6_600Style => Fonts.h6_600;
  TextStyle get h6_500Style => Fonts.h6_500;
  TextStyle get h6_400Style => Fonts.h6_400;

  // --- H7 스타일 (14px / 150% / -2%) ---
  TextStyle get h7_700Style => Fonts.h7_700;
  TextStyle get h7_600Style => Fonts.h7_600;
  TextStyle get h7_500Style => Fonts.h7_500;
  TextStyle get h7_400Style => Fonts.h7_400;

  // --- H8 스타일 (12px / 150% / -3%) ---
  TextStyle get h8_600Style => Fonts.h8_600;
  TextStyle get h8_500Style => Fonts.h8_500;
  TextStyle get h8_400Style => Fonts.h8_400;

  // --- H9 스타일 (10px / 150% / -2%) ---
  TextStyle get h9_600Style => Fonts.h9_600;
  TextStyle get h9_500Style => Fonts.h9_500;
}
