import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonFloatingActionButton extends StatelessWidget {
  const CommonFloatingActionButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: FloatingActionButton(
        heroTag: null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        backgroundColor: context.palette.primary,
        foregroundColor: context.palette.surface,
        onPressed: onPressed,
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  static const String heroTag = 'CommonFloatingActionButtonHeroTag';
}
