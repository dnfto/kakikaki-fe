import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonIconButton extends StatelessWidget {
  const CommonIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.padding = EdgeInsets.zero,
    this.primary,
    this.isLoading = false,
    this.alignment,
    this.size = Dimens.iconSize,
  });

  final Widget icon;
  final Color? primary;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onPressed;
  final AlignmentGeometry? alignment;
  final double size;
  final bool isLoading;

  bool get isDisable => onPressed == null;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = primary ?? context.palette.primary;
    final Color disabledForegroundColor =
        context.colorScheme.onSurface.withExactOpacity(0.2);

    return IconButton(
      style: IconButton.styleFrom(
        foregroundColor: foregroundColor,
        disabledForegroundColor: disabledForegroundColor,
        elevation: 0,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: padding,
        minimumSize: Size.square(size),
        alignment: alignment,
      ),
      onPressed: isLoading ? () {} : onPressed,
      iconSize: size,
      icon: AnimatedSize(
        duration: Params.animationDurationFast,
        curve: Curves.fastOutSlowIn,
        child: isLoading
            ? SizedBox.square(
                dimension: size - padding.vertical,
                child: FittedBox(
                    child: DefaultCircularProgressIndicator(
                        color: foregroundColor)),
              )
            : icon,
      ),
    );
  }
}
