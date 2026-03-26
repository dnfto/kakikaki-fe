import 'package:flutter/material.dart';
import 'package:kakikaki/core/extension/context_extension.dart';

class CommonDivider extends StatelessWidget {
  const CommonDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: color ?? context.palette.shadow);
  }
}

class DefaultVerticalDivider extends StatelessWidget {
  const DefaultVerticalDivider({super.key, this.color, this.size});

  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: size,
        child:
            VerticalDivider(width: 1, color: color ?? context.palette.shadow));
  }
}
