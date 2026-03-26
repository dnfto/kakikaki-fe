import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonTextButton extends StatelessWidget {
  const CommonTextButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.padding = Dimens.buttonPadding,
    this.textColor,
    this.isExpandedWidth = true,
    this.isLoading = false,
    this.alignment,
    this.height = Dimens.buttonHeight,
    this.width = 0.0,
    this.borderRadius = Dimens.buttonRadius,
    this.textStyle,
    this.fontSize,
  });

  final String text;

  final Color? textColor;
  final TextStyle? textStyle;
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
  final double? fontSize;

  bool get isDisable => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = textColor ?? context.palette.primary;
    final Color? disabledForegroundColor = textColor?.withExactOpacity(0.2);

    final buttonChild = AnimatedSize(
      duration: Params.animationDurationFast,
      curve: Curves.fastOutSlowIn,
      child: isLoading
          ? SizedBox(
              height: height - padding.vertical,
              child: FittedBox(
                child: DefaultCircularProgressIndicator(color: foregroundColor),
              ),
            )
          : Text(
              text,
              style: textStyle ??
                  context.h6_700Style.copyWith(color: foregroundColor),
            ),
    );

    ButtonStyle createButtonStyle(Size minimumSize) {
      return TextButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle:
            textStyle ?? context.h6_400Style.copyWith(fontSize: fontSize),
        minimumSize: minimumSize,
        alignment: alignment,
      );
    }

    return isExpandedWidth
        ? TextButton(
            style: createButtonStyle(Size(double.infinity, height)),
            onPressed: isLoading ? () {} : onPressed,
            onLongPress: isLoading ? () {} : onLongPress,
            onHover: onHover,
            onFocusChange: onFocusChange,
            child: buttonChild,
          )
        : SizedBox(
            width: width > 0 ? width : null,
            child: TextButton(
              style: createButtonStyle(Size(0, height)),
              onPressed: isLoading ? () {} : onPressed,
              onLongPress: isLoading ? () {} : onLongPress,
              onHover: onHover,
              onFocusChange: onFocusChange,
              child: buttonChild,
            ),
          );
  }
}
