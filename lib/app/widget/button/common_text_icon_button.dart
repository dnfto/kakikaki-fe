import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonTextIconButton extends StatelessWidget {
  const CommonTextIconButton({
    super.key,
    this.gap = 4,
    this.reversed = false,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.onLongPress,
    this.onHover,
    this.onFocusChange,
    this.padding = Dimens.buttonPadding,
    this.primary,
    this.isExpandedWidth = true,
    this.isLoading = false,
    this.alignment,
    this.height = Dimens.buttonHeight,
    this.width = 0.0,
    this.borderRadius = Dimens.buttonRadius,
  });

  final double gap;
  final bool reversed;
  final Widget icon;
  final Widget label;
  final Color? primary;
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

  bool get isDisable => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = primary ?? context.palette.primary;
    final Color? disabledForegroundColor = primary?.withExactOpacity(0.2);

    List<Widget> items = <Widget>[
      AnimatedSize(
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
      SizedBox(width: gap),
      Flexible(child: label),
    ];

    if (reversed) {
      items = items.reversed.toList();
    }

    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: disabledForegroundColor,
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
      onPressed: isLoading ? () {} : onPressed,
      onLongPress: isLoading ? () {} : onLongPress,
      onHover: onHover,
      onFocusChange: onFocusChange,
      child: Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}
