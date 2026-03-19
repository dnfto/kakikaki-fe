/// Svg icon path for [CommonIcon] widget
class IconPath {
  const IconPath._();

  // 공통 아이콘 경로
  static const String iconsPath = 'assets/icons';
  static const String common = '$iconsPath/common';
  static const String pages = '$iconsPath/pages';

  // 공통 아이콘
  static const String onigiri = '$common/onigiri.svg';

  // home
  static const String home = '$pages/home';
  static const String calendar = '$home/calendar.svg';

  // auth
  static const String auth = '$pages/auth';
  static const String signInWithKakao = '$auth/btn_kakao.svg';
  static const String signInWithGoogle = '$auth/btn_google.svg';
  static const String signInWithApple = '$auth/btn_apple.svg';

  // study
  static const String study = '$pages/study';
  static const String eraser = '$study/eraser.svg';
}
