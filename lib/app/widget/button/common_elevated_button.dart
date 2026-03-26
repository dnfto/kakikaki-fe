import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonElevatedButton extends StatelessWidget {
  /// 디폴트 텍스트 스타일: h7_500Style
  const CommonElevatedButton({
    super.key,
    required this.text,
    this.isEnabled = true,
    this.isLoading = false,
    this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.padding = Dimens.buttonPadding,
    this.backgroundColor,
    this.pressedBackgroundColor,
    this.disabledBackgroundColor,
    this.enabledTextColor,
    this.disabledTextColor,
    this.isExpandedWidth = true,
    this.alignment,
    this.height = Dimens.buttonHeight,
    this.width = 150,
    this.borderRadius = Dimens.buttonRadius,
    this.border,
    this.textStyle,
    this.boxShadow,
  });

  final String text; // 버튼 텍스트
  final TextStyle? textStyle; // 텍스트 스타일
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor; // 기본 색상
  final Color? pressedBackgroundColor; // 눌렸을 때 색상
  final Color? disabledBackgroundColor; // 비활성화 색상
  final Color? enabledTextColor; // 활성화된 상태에서의 텍스트 색상
  final Color? disabledTextColor; // 비활성화 상태에서의 텍스트 색상
  final EdgeInsetsGeometry padding; // 버튼 내부 여백
  final VoidCallback? onPressed; // 버튼 클릭 이벤트
  final VoidCallback? onLongPress; // 버튼 길게 누르기 이벤트
  final ValueChanged<bool>? onHover; // 마우스 호버 이벤트
  final ValueChanged<bool>? onFocusChange; // 포커스 이벤트
  final bool isExpandedWidth; // 버튼이 전체 너비를 차지할지 여부
  final AlignmentGeometry? alignment; // 텍스트 정렬
  final double height; // 버튼 높이
  final double width; // 버튼 너비
  final bool isLoading; // 로딩 상태 여부
  final BorderRadiusGeometry borderRadius; // 버튼 모서리 둥글기
  final BorderSide? border; // 버튼 테두리
  final bool isEnabled; // 버튼 활성화 여부

  bool get isDisable => !isEnabled || onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Color baseBg = backgroundColor ?? context.palette.onSurface;
    final Color pressBg =
        pressedBackgroundColor ?? baseBg.withExactOpacity(0.7);

    // backgroundColor가 명시적으로 설정되면 disabled 상태에서도 그 색상 사용
    final Color disableBg = disabledBackgroundColor ??
        (backgroundColor != null ? backgroundColor! : Palette.gray20);

    final Color baseFg = enabledTextColor ?? context.palette.onPrimary;
    final Color disableFg = disabledTextColor ?? Palette.white;

    final ButtonStyle style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disableBg;
        if (states.contains(WidgetState.pressed)) return pressBg;
        return baseBg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return disableFg;
        return baseFg;
      }),
      minimumSize: WidgetStateProperty.all(
        Size(isExpandedWidth ? double.infinity : width, height),
      ),
      padding: WidgetStateProperty.all(padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: border ?? BorderSide.none,
        ),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      elevation: WidgetStateProperty.all(0),
      alignment: alignment,
    );

    final buttonTextWidget = Text(
      text,
      style: textStyle ??
          context.h6_600Style.copyWith(
            color: isDisable ? disableFg : baseFg,
          ),
    );

    final buttonChild = AnimatedSize(
      duration: Params.animationDurationFast,
      curve: Curves.fastOutSlowIn,
      child: Center(
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20, // 스피너 크기 조절
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(baseFg),
                    ),
                  ),
                  const SizedBox(width: 8), // 스피너와 텍스트 사이 간격
                  buttonTextWidget,
                ],
              )
            : buttonTextWidget,
      ),
    );

    final button = isExpandedWidth
        ? ElevatedButton(
            style: style,
            onPressed: isLoading ? () {} : (isEnabled ? onPressed : null),
            onLongPress: isLoading ? () {} : (isEnabled ? onLongPress : null),
            onHover: onHover,
            onFocusChange: onFocusChange,
            child: buttonChild,
          )
        : IntrinsicWidth(
            child: ElevatedButton(
              style: style,
              onPressed: isLoading ? () {} : (isEnabled ? onPressed : null),
              onLongPress: isLoading ? () {} : (isEnabled ? onLongPress : null),
              onHover: onHover,
              onFocusChange: onFocusChange,
              child: buttonChild,
            ),
          );

    if (boxShadow != null) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: button,
      );
    }

    return button;
  }
}
