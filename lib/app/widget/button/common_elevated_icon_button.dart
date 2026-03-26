import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonElevatedIconButton extends StatelessWidget {
  const CommonElevatedIconButton({
    super.key,
    required this.icon,
    this.label,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.padding = Dimens.buttonPadding,
    this.primary,
    this.onPrimary,
    this.isExpandedWidth = true,
    this.isLoading = false,
    this.alignment,
    this.height = Dimens.buttonHeight,
    this.width = 0.0,
    this.borderRadius = Dimens.buttonRadius,
  });

  final Widget icon;
  final Widget? label;
  final Color? primary;
  final Color? onPrimary;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;
  final bool isExpandedWidth;
  final AlignmentGeometry? alignment;
  final double height;
  final double width;
  final bool isLoading;
  final BorderRadiusGeometry borderRadius;

  bool get isDisable => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = onPrimary ?? context.palette.onPrimary;
    final Color backgroundColor = primary ?? context.colorScheme.primary;
    final Color? disabledForegroundColor = onPrimary?.withExactOpacity(0.2);
    final Color? disabledBackgroundColor = primary?.withExactOpacity(0.2);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: backgroundColor,
        disabledForegroundColor: disabledForegroundColor,
        disabledBackgroundColor: disabledBackgroundColor,
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding,
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        textStyle: context.h6_400Style,
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
      icon: AnimatedSize(
        duration: Params.animationDurationFast,
        curve: Curves.fastOutSlowIn,
        child: isLoading
            ? SizedBox(
                height: height - padding.vertical,
                child: FittedBox(
                    child: DefaultCircularProgressIndicator(
                        color: foregroundColor)),
              )
            : icon,
      ),
      label: label ?? const SizedBox.shrink(),
    );
  }
}
