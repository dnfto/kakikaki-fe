import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:kakikaki/app/constants/constants.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 4.0,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Palette.gray20,
      highlightColor: Palette.gray10,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: Palette.gray20,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class SkeletonText extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonText({
    super.key,
    this.width,
    this.height = 14.0,
    this.borderRadius = 4.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class SkeletonImage extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonImage({
    super.key,
    this.width,
    this.height = 200.0,
    this.borderRadius = 12.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      width: width,
      height: height,
      borderRadius: borderRadius,
      margin: margin,
    );
  }
}

class SkeletonParagraph extends StatelessWidget {
  final int lines;
  final double lineHeight;
  final double spacing;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonParagraph({
    super.key,
    this.lines = 2,
    this.lineHeight = 14.0,
    this.spacing = 8.0,
    this.borderRadius = 4.0,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Palette.gray20,
      highlightColor: Palette.gray10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final isLastLine = index == lines - 1;
          return Column(
            children: [
              Container(
                width: isLastLine
                    ? MediaQuery.of(context).size.width * 0.7
                    : double.infinity,
                height: lineHeight,
                decoration: BoxDecoration(
                  color: Palette.gray20,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              if (!isLastLine) SizedBox(height: spacing),
            ],
          );
        }),
      ),
    );
  }
}
