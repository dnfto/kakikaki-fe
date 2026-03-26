import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';

/// 공통 Chip 위젯
///
/// 라벨과 배경색을 받아서 chip 형태로 표시합니다.
/// 선택적으로 아이콘을 추가할 수 있습니다.
///
/// 사용 예시:
/// ```dart
/// CommonChip(
///   label: 'N1',
///   color: Colors.red.shade100,
/// )
/// ```
///
/// 아이콘 포함 예시:
/// ```dart
/// CommonChip(
///   label: '미분류',
///   color: Colors.grey.shade200,
///   icon: Icons.folder,
/// )
/// ```
class CommonChip extends StatelessWidget {
  const CommonChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.icon,
    this.iconSize = 14,
    this.iconColor,
    this.labelColor,
    this.padding,
  });

  /// Chip에 표시할 텍스트
  final String label;

  /// Chip의 배경색
  final Color? backgroundColor;

  /// 선택적 아이콘 (왼쪽에 표시)
  final IconData? icon;

  /// 아이콘 크기 (기본값: 14)
  final double iconSize;

  /// 아이콘 색상 (기본값: Colors.grey)
  final Color? iconColor;

  /// 텍스트 색상
  final Color? labelColor;

  /// 내부 패딩 (기본값: EdgeInsets.symmetric(horizontal: 10, vertical: 4))
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            backgroundColor ?? context.palette.primary.withExactOpacity(0.25),
        borderRadius: Dimens.tagRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? context.palette.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.h8_600Style
                .copyWith(color: labelColor ?? context.palette.onSurface),
          ),
        ],
      ),
    );
  }
}
