import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

/// 앱 전역에서 사용하는 공통 Scaffold
///
/// 선택적으로 다음 컴포넌트를 사용할 수 있습니다:
///
/// **AppBar 사용 예시:**
/// ```dart
/// CommonScaffold(
///   appBar: CommonAppbar(title: '제목'),
///   body: MyWidget(),
/// )
/// ```
///
/// **FloatingActionButton 사용 예시:**
/// ```dart
/// CommonScaffold(
///   floatingActionButton: CommonFloatingActionButton(
///     onPressed: () => print('FAB 클릭'),
///   ),
///   body: MyWidget(),
/// )
/// ```
///
/// **BottomNavigationBar 사용 예시:**
/// ```dart
/// CommonScaffold(
///   bottomNavigationBar: CommonBottomNavBar(),
///   body: MyWidget(),
/// )
/// ```
class CommonScaffold extends StatelessWidget {
  const CommonScaffold({
    super.key,
    this.appBar,
    this.drawer,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.hideKeyboardWhenTouchOutside = true,
    this.actionOnTapOutside,
    this.resizeToAvoidBottomInset,
  });

  /// AppBar (CommonAppbar 또는 DefaultCommonAppbar 사용 권장)
  final PreferredSizeWidget? appBar;
  final Widget? drawer;
  final Widget? body;

  /// FloatingActionButton (CommonFloatingActionButton 사용 권장)
  final Widget? floatingActionButton;

  /// FloatingActionButton 위치
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// BottomNavigationBar (CommonBottomNavBar 사용 권장)
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool hideKeyboardWhenTouchOutside;
  final VoidCallback? actionOnTapOutside;
  final bool? resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: backgroundColor ?? context.palette.surface,
      body: body,
      appBar: appBar,
      drawer: drawer,
      drawerScrimColor: Colors.transparent,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? false,
    );

    return hideKeyboardWhenTouchOutside
        ? GestureDetector(
            onTap: () {
              _hideKeyboard(context);
              if (actionOnTapOutside != null) {
                actionOnTapOutside!();
              }
            },
            child: scaffold,
          )
        : scaffold;
  }

  static void _hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);

    if (!currentFocus.hasPrimaryFocus) {
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }
}
