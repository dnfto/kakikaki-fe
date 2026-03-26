import 'package:kakikaki/app/constants/dimens.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/widget/button/common_elevated_button.dart';
import 'package:kakikaki/app/widget/button/common_outlined_button.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

import 'package:kakikaki/l10n/app_localizations.dart';

/// 리스트 선택 다이얼로그에서 사용할 항목
class ListChoiceItem<T> {
  const ListChoiceItem({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final T value;
  final IconData? icon;
  final Color? iconColor;
}

/// 앱 전역에서 사용하는 다이얼로그 위젯
///
/// 다양한 형태의 다이얼로그를 제공합니다:
/// - 기본 다이얼로그 (제목, 내용, 버튼)
/// - 커스텀 액션 위젯을 사용하는 다이얼로그
/// - 입력 필드가 있는 다이얼로그

class CommonDialogue extends StatelessWidget {
  final String? title;
  final TextStyle? titleStyle;
  final String content;
  final TextStyle? contentStyle;
  final String? outlineButtonText;
  final Color? outlinedButtonTextColor;
  final Color? outlinedButtonTextBorderColor;
  final String? elevatedButtonText;
  final Color? elevatedButtonTextColor;
  final Color? elevatedButtonColor;
  final VoidCallback? onOutlinedButtonPressed;
  final VoidCallback onElevatedButtonPressed;

  /// outline 버튼으로 닫을 때 pop(result)에 넣을 값. null이면 pop()만 호출
  final Object? outlinePopValue;

  /// elevated 버튼으로 닫을 때 pop(result)에 넣을 값. null이면 true 사용
  final Object? elevatedPopValue;
  final bool useRootNavigator;
  final bool? barrierDismissible;

  const CommonDialogue({
    super.key,
    this.title,
    this.titleStyle,
    required this.content,
    this.contentStyle,
    this.outlineButtonText,
    this.outlinedButtonTextColor,
    this.outlinedButtonTextBorderColor,
    this.elevatedButtonText,
    this.elevatedButtonTextColor,
    this.elevatedButtonColor,
    this.onOutlinedButtonPressed,
    required this.onElevatedButtonPressed,
    this.outlinePopValue,
    this.elevatedPopValue,
    this.useRootNavigator = false,
    this.barrierDismissible = true,
  });

  static Future<bool?> showTwoChoiceConfirmDialogue({
    required BuildContext context,
    String? title,
    required String content,
    String? outlineButtonText,
    String? elevatedButtonText,
    bool? barrierDismissible,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext dialogContext) {
        return CommonDialogue(
          title: title,
          content: content,
          outlineButtonText:
              outlineButtonText ?? dialogContext.l10n.action_cancel,
          elevatedButtonText:
              elevatedButtonText ?? dialogContext.l10n.action_confirm,
          barrierDismissible: barrierDismissible,
          // 여기서 pop 하지 않고 build의 onPressed에서 처리함.
          onOutlinedButtonPressed: () {},
          onElevatedButtonPressed: () {},
        );
      },
    );
  }

  /// 리스트에서 한 항목 선택하는 다이얼로그
  /// 반환: 선택한 항목의 value, 바깥 탭/취소 시 null
  static Future<T?> showListChoiceDialogue<T>({
    required BuildContext context,
    required String title,
    required List<ListChoiceItem<T>> items,
    double maxHeight = 300,
    bool? barrierDismissible,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: dialogContext.palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Dimens.defaultDialogueRadius,
          ),
          child: Container(
            width: dialogContext.screenWidth * 0.9,
            padding: EdgeInsets.all(dialogContext.screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: dialogContext.h5_700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: ListView(
                    shrinkWrap: true,
                    children: items
                        .map(
                          (item) => InkWell(
                            onTap: () =>
                                Navigator.of(dialogContext).pop(item.value),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  if (item.icon != null) ...[
                                    Icon(
                                      item.icon,
                                      color: item.iconColor ??
                                          dialogContext.palette.primary,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                  ],
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: dialogContext.h6_400Style,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 버튼 두 개 (취소/확인) 다이얼로그
  /// 반환: elevated 누르면 [elevatedResult] 또는 true, outline 누르면 [outlineResult], 바깥 탭이면 null
  static Future<T?> showTwoChoiceDialogue<T>({
    required BuildContext context,
    String? title,
    TextStyle? titleStyle,
    required String content,
    TextStyle? contentStyle,
    String? outlineButtonText,
    Color? outlinedButtonTextColor,
    Color? outlinedButtonTextBorderColor,
    String? elevatedButtonText,
    Color? elevatedButtonTextColor,
    Color? elevatedButtonColor,
    T? outlineResult,
    T? elevatedResult,
    VoidCallback? onOutlinedButtonPressed,
    required VoidCallback onElevatedButtonPressed,
    bool? barrierDismissible,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext context) {
        return CommonDialogue(
          title: title,
          titleStyle: titleStyle,
          content: content,
          contentStyle: contentStyle,
          outlineButtonText: outlineButtonText ?? context.l10n.action_cancel,
          outlinedButtonTextColor: outlinedButtonTextColor,
          outlinedButtonTextBorderColor: outlinedButtonTextBorderColor,
          elevatedButtonText: elevatedButtonText ?? context.l10n.action_confirm,
          elevatedButtonTextColor: elevatedButtonTextColor,
          elevatedButtonColor: elevatedButtonColor,
          outlinePopValue: outlineResult,
          elevatedPopValue: elevatedResult ?? true,
          barrierDismissible: barrierDismissible,
          onOutlinedButtonPressed: onOutlinedButtonPressed,
          onElevatedButtonPressed: onElevatedButtonPressed,
        );
      },
    );
  }

  /// 버튼 한 개 (확인 전용) 다이얼로그
  static Future<void> showOneChoiceDialogue({
    required BuildContext context,
    String? title,
    TextStyle? titleStyle,
    required String content,
    TextStyle? contentStyle,
    String? elevatedButtonText,
    Color? elevatedButtonTextColor,
    Color? elevatedButtonColor,
    required VoidCallback onElevatedButtonPressed,
    bool? barrierDismissible,
    bool blockBackButton = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext context) {
        final dialog = CommonDialogue(
          title: title,
          titleStyle: titleStyle,
          content: content,
          contentStyle: contentStyle,
          outlineButtonText: null,
          elevatedButtonText: elevatedButtonText ?? context.l10n.action_confirm,
          elevatedButtonTextColor: elevatedButtonTextColor,
          elevatedButtonColor: elevatedButtonColor,
          barrierDismissible: barrierDismissible,
          onElevatedButtonPressed: onElevatedButtonPressed,
        );

        if (!blockBackButton) return dialog;
        return PopScope(
          canPop: false,
          child: dialog,
        );
      },
    );
  }

  /// 뒤로가기 확인 다이얼로그
  static Future<void> showBackConfirmationDialog({
    required BuildContext context,
    required String title,
    bool? barrierDismissible,
  }) {
    return showTwoChoiceDialogue(
      context: context,
      title: title,
      content: '작성 중인 내용이 모두 사라집니다.\n정말 나가시겠습니까?',
      barrierDismissible: barrierDismissible,
      onElevatedButtonPressed: () {
        Navigator.of(context).pop(); // 페이지 나가기 실행 (다이얼로그는 이미 내부 build에서 pop됨)
      },
    );
  }

  /// 💡 입력 필드 다이얼로그 (렉 없이 수정됨)
  static Future<String?> showInputDialogue({
    required BuildContext context,
    required String title,
    required String hintText,
    String? outlineButtonText,
    String? elevatedButtonText,
    String? initialValue,
    int maxLines = 1,
    int? maxLength,
    bool useRootNavigator = false,
    bool? barrierDismissible,
  }) {
    FocusManager.instance.primaryFocus?.unfocus();
    print(
      '[CommonDialogue.showInputDialogue] open '
      'title="$title", useRootNavigator=$useRootNavigator, '
      'barrierDismissible=${barrierDismissible ?? true}',
    );

    return showDialog<String?>(
      context: context,
      useRootNavigator: useRootNavigator,
      requestFocus: false,
      barrierDismissible: barrierDismissible ?? true,
      builder: (BuildContext dialogContext) {
        print(
          '[CommonDialogue.showInputDialogue] builder '
          'dialogContextMounted=${dialogContext.mounted}',
        );
        return _InputDialogueWidget(
          title: title,
          hintText: hintText,
          outlineButtonText: outlineButtonText,
          elevatedButtonText: elevatedButtonText,
          initialValue: initialValue,
          maxLines: maxLines,
          maxLength: maxLength,
          useRootNavigator: useRootNavigator,
        );
      },
    ).then((result) {
      FocusManager.instance.primaryFocus?.unfocus();
      print(
        '[CommonDialogue.showInputDialogue] closed '
        'result=${result == null ? 'null' : '"$result"'}',
      );
      return result;
    });
  }

  /// 네트워크 오류 다이얼로그 (전역)
  static bool _isNetworkErrorDialogShowing = false;

  static Future<void> showNetworkErrorDialog() async {
    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted || _isNetworkErrorDialogShowing) {
      return;
    }
    _isNetworkErrorDialogShowing = true;

    final l10n = AppLocalizations.of(context);
    final title = l10n.network_error_title;
    final content = l10n.network_error_content;

    await showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true, // 전역 관리
      builder: (BuildContext dialogContext) {
        return CommonDialogue(
          title: title,
          content: content,
          useRootNavigator: true, // 내부 pop 시 rootNavigator 사용하도록 설정
          elevatedButtonText: dialogContext.l10n.action_confirm,
          onElevatedButtonPressed: () {
            _isNetworkErrorDialogShowing = false;
          },
          outlineButtonText: null,
          onOutlinedButtonPressed: null,
        );
      },
    ).then((_) => _isNetworkErrorDialogShowing = false);
  }

  @override
  Widget build(BuildContext context) {
    // 다이얼로그를 닫을 네비게이터 선택
    final navigator = Navigator.of(context, rootNavigator: useRootNavigator);

    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(borderRadius: Dimens.defaultDialogueRadius),
      child: Container(
        width: context.screenWidth * 0.9,
        padding: EdgeInsets.all(context.screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: titleStyle ?? context.h5_700Style,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              content,
              style: contentStyle ??
                  context.h7_400Style.copyWith(color: Palette.gray70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (outlineButtonText != null) ...[
                  Expanded(
                    child: CommonOutlinedButton(
                      foregroundColor:
                          outlinedButtonTextBorderColor ?? Palette.gray30,
                      textColor:
                          outlinedButtonTextColor ?? context.palette.primary,
                      height: 35,
                      onPressed: () {
                        navigator.pop(outlinePopValue);
                        onOutlinedButtonPressed?.call();
                      },
                      label: outlineButtonText!,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: CommonElevatedButton(
                    height: 35,
                    backgroundColor:
                        elevatedButtonColor ?? context.palette.primary,
                    onPressed: () {
                      navigator.pop(elevatedPopValue ?? true);
                      onElevatedButtonPressed();
                    },
                    text: elevatedButtonText ?? context.l10n.action_confirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// `showInputDialogue` 전용 — 렉 없이 깔끔하게 닫히도록 수정한 위젯
class _InputDialogueWidget extends StatefulWidget {
  const _InputDialogueWidget({
    required this.title,
    required this.hintText,
    this.outlineButtonText,
    this.elevatedButtonText,
    this.initialValue,
    this.maxLines = 1,
    this.maxLength,
    this.useRootNavigator = false,
  });

  final String title;
  final String hintText;
  final String? outlineButtonText;
  final String? elevatedButtonText;
  final String? initialValue;
  final int maxLines;
  final int? maxLength;
  final bool useRootNavigator;

  @override
  State<_InputDialogueWidget> createState() => _InputDialogueWidgetState();
}

class _InputDialogueWidgetState extends State<_InputDialogueWidget> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    print('[CommonDialogue._InputDialogueWidget] initState');
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void deactivate() {
    print('[CommonDialogue._InputDialogueWidget] deactivate');
    super.deactivate();
  }

  @override
  void dispose() {
    print('[CommonDialogue._InputDialogueWidget] dispose');
    // 💡 메모리 누수 및 렉 방지
    _controller.dispose();
    super.dispose();
  }

  void _closeDialog(String? result) {
    print(
      '[CommonDialogue._InputDialogueWidget] close requested '
      'result=${result == null ? 'null' : '"$result"'} '
      '(useRootNavigator=${widget.useRootNavigator})',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    final navigator =
        Navigator.of(context, rootNavigator: widget.useRootNavigator);
    if (!navigator.canPop()) {
      print('[CommonDialogue._InputDialogueWidget] skip pop: cannot pop');
      return;
    }
    navigator.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    print('[CommonDialogue._InputDialogueWidget] build');
    return Dialog(
      backgroundColor: context.palette.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(context.screenWidth * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: context.h5_700Style),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      BorderSide(color: context.palette.primary, width: 2),
                ),
              ),
              maxLines: widget.maxLines,
              maxLength: widget.maxLength,
              autofocus: false,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CommonOutlinedButton(
                    height: 35,
                    foregroundColor: Palette.gray30,
                    textColor: context.palette.primary,
                    label:
                        widget.outlineButtonText ?? context.l10n.action_cancel,
                    onPressed: () => _closeDialog(null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CommonElevatedButton(
                    height: 35,
                    text: widget.elevatedButtonText ??
                        context.l10n.action_confirm,
                    onPressed: () {
                      final text = _controller.text.trim();
                      _closeDialog(text.isNotEmpty ? text : null);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
