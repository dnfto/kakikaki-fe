import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonOutlinedButton extends StatelessWidget {
  const CommonOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.padding = Dimens.buttonPadding,
    this.isExpandedWidth = true,
    this.isLoading = false,
    this.alignment,
    this.height = Dimens.buttonHeight,
    this.width = 0.0,
    this.borderRadius = Dimens.buttonRadius,
    this.borderWidth = 1.0,
    this.textStyle,
    this.textColor,
    this.foregroundColor,
    this.backgroundColor,
    this.boxShadow,
  });

  final String label;
  final Color? foregroundColor; // 테두리 및 기본 효과 색상
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;
  final bool isExpandedWidth;
  final AlignmentGeometry? alignment;
  final bool isLoading;
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;
  final double borderWidth;
  final TextStyle? textStyle;
  final Color? textColor;

  bool get isDisable => onPressed == null;

  @override
  Widget build(BuildContext context) {
    // 외부에서 지정하지 않으면 기본적으로 gray30을 테두리/전경색으로 사용 (다이얼로그 보조 버튼 최적화)
    final Color foreground = foregroundColor ?? context.palette.primary;

    final Color disabledForegroundColor =
        context.colorScheme.onSurface.withExactOpacity(0.2);

    // 텍스트 컬러 우선순위: textColor 파라미터 > foreground (지정된 테두리색)
    final TextStyle effectiveTextStyle =
        (textStyle ?? context.h6_600Style).copyWith(
      color: textColor ?? foreground,
    );

    final button = OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground,
        disabledForegroundColor: disabledForegroundColor,
        backgroundColor: backgroundColor ?? context.palette.surface,
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding,
        side: BorderSide(
          // 비활성화 시에는 연한 회색, 활성화 시에는 foreground(= 지정된 색 혹은 gray30)
          color: isDisable ? disabledForegroundColor : foreground,
          width: borderWidth,
        ),
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: effectiveTextStyle,
        minimumSize: Size(
          isExpandedWidth ? double.infinity : width,
          height,
        ),
        alignment: alignment,
      ),
      onPressed: isLoading ? null : onPressed,
      onLongPress: isLoading ? null : onLongPress,
      onHover: onHover,
      onFocusChange: onFocusChange,
      child: RepaintBoundary(
        child: AnimatedSize(
          duration: Params.animationDurationFast,
          curve: Curves.fastOutSlowIn,
          child: isLoading
              ? SizedBox(
                  height: height - padding.vertical,
                  child: FittedBox(
                    child: DefaultCircularProgressIndicator(
                      color: foreground,
                    ),
                  ),
                )
              : Text(
                  label,
                  style: effectiveTextStyle,
                  textAlign: TextAlign.center,
                ),
        ),
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
