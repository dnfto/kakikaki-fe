import 'package:kakikaki/app/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/utils/utils.dart';

class CommonIcon extends StatelessWidget {
  const CommonIcon(
    this.icon, {
    this.padding = EdgeInsets.zero,
    this.size = Dimens.iconSize,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    super.key,
  }) : onPressed = null;

  const CommonIcon.button(
    this.icon, {
    required this.onPressed,
    this.padding = EdgeInsets.zero,
    this.size = Dimens.iconSize,
    this.colorFilter,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    super.key,
  });

  final String? icon;

  final double? size;

  final BoxFit fit;

  final ColorFilter? colorFilter;

  final AlignmentGeometry alignment;

  final VoidCallback? onPressed;

  final EdgeInsetsGeometry padding;

  static ColorFilter fillColor(Color color) =>
      ColorFilter.mode(color, BlendMode.srcIn);

  @override
  Widget build(BuildContext context) {
    if (icon?.isEmpty ?? true) {
      return SizedBox.square(
          dimension: size, child: const DefaultCircularProgressIndicator());
    }

    Widget? result;

    if (StringUtils.isURL(icon!)) {
      result = SvgPicture.network(
        icon!,
        width: size,
        height: size,
        alignment: alignment,
        fit: fit,
        colorFilter: colorFilter,
      );
    }

    result ??= SvgPicture.asset(
      icon!,
      width: size,
      height: size,
      alignment: alignment,
      fit: fit,
      colorFilter: colorFilter,
    );

    if (onPressed != null) {
      result = IconButton(
          alignment: alignment,
          padding: padding,
          onPressed: onPressed,
          icon: result);
    } else {
      result = Padding(padding: padding, child: result);
    }

    if (size != null) {
      result = SizedBox(
        width: size! + padding.horizontal,
        height: size! + padding.vertical,
        child: result,
      );
    }

    return result;
  }
}
