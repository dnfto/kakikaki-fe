import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';

/// 빈 상태를 표시하는 공통 위젯
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.text,
    this.icon,
    this.iconSize = 72,
    this.iconColor,
    this.topPadding = 180,
    this.textStyle,
    /// 다른 [ListView] / 스크롤 안에 넣을 때 `true` — 내부 [ListView] 중첩으로 인한
    /// "Vertical viewport was given unbounded height" 방지
    this.shrinkWrap = false,
  });

  /// 표시할 텍스트
  final String text;

  /// 아이콘 (null이면 기본 아이콘 사용)
  final IconData? icon;

  /// 아이콘 크기
  final double iconSize;

  /// 아이콘 색상 (null이면 기본 색상 사용)
  final Color? iconColor;

  /// 상단 여백
  final double topPadding;

  /// 텍스트 스타일 (null이면 기본 스타일 사용)
  final TextStyle? textStyle;

  /// 부모가 이미 스크롤 가능할 때만 true (예: [ListView]의 child)
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topPadding),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon ?? Icons.emoji_objects_outlined,
                size: iconSize,
                color: iconColor ?? Palette.gray40,
              ),
              const SizedBox(height: 12),
              Text(
                text,
                style: textStyle ??
                    context.h6_400Style.copyWith(color: Palette.gray60),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );

    if (shrinkWrap) {
      return body;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [body],
    );
  }
}
