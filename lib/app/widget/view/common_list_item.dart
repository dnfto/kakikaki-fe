import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonListItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isDanger;
  final bool disabled;
  final IconData? icon;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry contentPadding;
  final bool showDivider;

  const CommonListItem({
    super.key,
    required this.title,
    this.onTap,
    this.isDanger = false,
    this.disabled = false,
    this.icon,
    this.leading,
    this.trailing,
    this.textStyle,
    this.contentPadding =
        const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTappable = onTap != null && !disabled;

    final Color resolvedColor = disabled
        ? Palette.gray50
        : isDanger
            ? Palette.red50
            : Palette.black;

    final Widget? resolvedLeading = leading ??
        (icon != null
            ? Icon(
                icon,
                color: resolvedColor,
              )
            : null);

    final Widget tile = ListTile(
      enabled: isTappable,
      contentPadding: contentPadding,
      onTap: isTappable ? onTap : null,
      title: Text(
        title,
        style: textStyle ?? context.h6_600Style,
      ),
      leading: resolvedLeading,
      trailing: trailing, // 기본값 제거됨 → 명시한 경우에만 표시
    );

    if (showDivider) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile,
          const Divider(height: 1),
        ],
      );
    }

    return tile;
  }
}
