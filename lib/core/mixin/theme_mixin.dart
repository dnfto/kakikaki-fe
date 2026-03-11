import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/validate_utils.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Common using Theme, language, isDark,...
// `on State<T>`: State<T>를 상속받는 클래스에서만 사용 가능. 즉 `StatefulWidget`의 상태 클레스에만 적용 가능
mixin ThemeMixin<T extends StatefulWidget> on State<T> {
  late AppLocalizations l10n;
  late ColorScheme colorScheme;
  late ThemeData appThemes;
  late TextTheme textStyle;

  // 의존성이 변경되었을 때 호출된다.
  // 따라서 테마나 언어 설정이 변경됐을 때도 실행된다.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    l10n = context.l10n;
    colorScheme = context.colorScheme;
    appThemes = context.appTheme;
    textStyle = context.textStyle;

    Validation.l10n = l10n;
  }

  // 오버라이딩을 통해 setState 실행 시 위젯이 마운트된 상태인지 검사한다.
  // mounted: 위젯이 여전히 UI 트리에 존재하는지 확인
  // 위젯이 마운트되지 않은 상태에서 setState를 호출하면 에러가 발생하기 때문에 안전성을 높인다.
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

/*
< 사용 예시 >
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with ThemeMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle), // 다국어 문자열 사용
      ),
      body: Center(
        child: Text(
          '현재 테마는 ${isDarkTheme ? '다크' : '라이트'} 모드',
          style: textStyle.headlineMedium, // 텍스트 스타일 사용
        ),
      ),
      backgroundColor: colorScheme.background, // 배경 색상
    );
  }
}
 */
