import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/cupertino.dart';

class CommonSlidingSegmented extends StatelessWidget {
  const CommonSlidingSegmented({
    super.key,
    this.initalValue = 0,
    this.onChanged,
    required this.children,
  });

  final int initalValue;
  final ValueChanged<int>? onChanged;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return CupertinoSegmentedControl<int>(
      groupValue: initalValue,
      padding: EdgeInsets.zero,
      borderColor: palette.shadow,
      unselectedColor: palette.surface,
      selectedColor: palette.primary,
      onValueChanged: (value) => onChanged?.call(value),
      children: children.asMap(),
    );
  }
}
