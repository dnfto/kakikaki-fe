import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'common_icon.dart';

class CommonErrorImage extends StatelessWidget {
  const CommonErrorImage({
    super.key,
    this.width,
    this.height,
    this.isRounded = false,
    this.borderRadius,
    this.image,
  });

  final double? width, height;
  final bool isRounded;
  final BorderRadiusGeometry? borderRadius;
  final String? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.shadow,
        shape: isRounded ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: borderRadius,
      ),
      child: image != null
          ? CommonIcon(
              image,
              size: height ?? width ?? Dimens.iconSize,
              colorFilter: CommonIcon.fillColor(context.colorScheme.primary),
            )
          : Icon(Icons.error_outline),
    );
  }
}
