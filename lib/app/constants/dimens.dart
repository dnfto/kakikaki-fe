import 'package:flutter/widgets.dart';

/// 앱의 디폴트 설정(size, pading, border,...)
class Dimens {
  Dimens._();

  static const double imageSize = 50.0;
  static const double imageHeight = 50.0;
  static const double imageWidth = 80.0;
  static const BorderRadius imageRadius = BorderRadius.all(Radius.circular(10));
  static const BorderRadius defaultDialogueRadius =
      BorderRadius.all(Radius.circular(20));

  static const double iconSize = 24.0;

  static const double buttonHeight = 30.0;
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(10));
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 8);

  static const BorderRadius tagRadius = BorderRadius.all(Radius.circular(20));
  static const double bottomSheetGap = 24.0;
  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(20),
    topRight: Radius.circular(20),
  );

  static const double dialogWidth = 300.0;
  static const double dialogGap = 24.0;
  static const EdgeInsets dialogPadding =
      EdgeInsets.symmetric(horizontal: 15.0, vertical: 24.0);
  static const BorderRadius dialogRadius =
      BorderRadius.all(Radius.circular(10));

  static const double appbarHeight = 64.0;
  static const double appbarLeadingSize = 18.0;
  static const EdgeInsets appbarLeadingPading =
      EdgeInsets.only(right: 10, left: 20);

  static const double creadcrumbHeight = 32.0;

  static const double drawerWidth = 300.0;

  static const EdgeInsets cardPadding =
      EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0);
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(10));
  static const double cardGap = 12.0;

  static const double navigationBarHeight = 10.0;
}
