import 'package:flutter/material.dart';
import 'package:kakikaki/core/extension/extension.dart';

enum ArrowDirection {
  bottomLeft,
  bottomCenter, // 가운데 방향 추가
  bottomRight,
}

class ArrowConfig {
  final double width;
  final double height;
  final double position; // bottomLeft, bottomRight일 때 가장자리로부터의 거리
  final bool isAbsolutePosition;

  const ArrowConfig({
    this.width = 12.0,
    this.height = 8.0,
    this.position = 24.0,
    this.isAbsolutePosition = true,
  });
}

class BubbleContainer extends StatelessWidget {
  final Widget? child;
  final String? text; // 텍스트를 바로 넣을 수 있는 파라미터 추가
  final TextStyle? textStyle; // 텍스트 스타일 커스텀
  final Color? backgroundColor;
  final ArrowDirection arrowDirection;
  final ArrowConfig arrowConfig;
  final double borderRadius;
  final EdgeInsets? padding;

  /// 말풍선의 고정 너비. null이면 자식 크기에 맞춤.
  final double? width;

  /// 말풍선의 최대 너비. null이면 제한 없음. width가 있으면 무시됨.
  final double? maxWidth;

  const BubbleContainer({
    super.key,
    this.child,
    this.text,
    this.textStyle,
    this.backgroundColor,
    this.arrowDirection = ArrowDirection.bottomRight,
    this.arrowConfig = const ArrowConfig(),
    this.borderRadius = 16.0,
    this.padding,
    this.width,
    this.maxWidth,
  }) : assert(child != null || text != null, 'child나 text 중 하나는 반드시 입력해야 합니다.');

  @override
  Widget build(BuildContext context) {
    // 기본 패딩 (텍스트를 넣었을 때 예뻐 보이도록 상하좌우 여백 설정)
    final effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

    // text가 있으면 Text 위젯 사용, 없으면 child 위젯 사용
    final contentWidget = text != null
        ? Text(text!,
            style: textStyle ??
                context.h7_600Style.copyWith(color: context.palette.onPrimary))
        : child!;
    final paddedContent = Padding(
      padding: _calculatePaddingWithArrow(effectivePadding),
      child: width != null
          ? SizedBox(width: width, child: contentWidget)
          : contentWidget,
    );

    Widget bubble = CustomPaint(
      painter: _BubblePainter(
        color: backgroundColor ?? context.palette.primary,
        arrowDirection: arrowDirection,
        arrowConfig: arrowConfig,
        borderRadius: borderRadius,
      ),
      child: paddedContent,
    );

    if (width != null) {
      bubble = SizedBox(width: width!, child: bubble);
    } else if (maxWidth != null) {
      bubble = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: bubble,
      );
    }
    return bubble;
  }

  EdgeInsets _calculatePaddingWithArrow(EdgeInsets basePadding) {
    if (arrowDirection == ArrowDirection.bottomLeft ||
        arrowDirection == ArrowDirection.bottomCenter ||
        arrowDirection == ArrowDirection.bottomRight) {
      return basePadding.copyWith(
          bottom: basePadding.bottom + arrowConfig.height);
    }
    return basePadding;
  }
}

class _BubblePainter extends CustomPainter {
  final Color color;
  final ArrowDirection arrowDirection;
  final ArrowConfig arrowConfig;
  final double borderRadius;

  _BubblePainter({
    required this.color,
    required this.arrowDirection,
    required this.arrowConfig,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true; // 경계면을 부드럽게 처리

    final path = Path();
    final bodyHeight = size.height - arrowConfig.height;
    final bodyWidth = size.width;

    // 1. 메인 박스 그리기
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, bodyWidth, bodyHeight),
      Radius.circular(borderRadius),
    ));

    // 2. 둥근 삼각형 화살표 그리기 로직
    if (arrowDirection == ArrowDirection.bottomRight ||
        arrowDirection == ArrowDirection.bottomLeft ||
        arrowDirection == ArrowDirection.bottomCenter) {
      // 방향에 따른 화살표의 팁(꼭짓점) X 좌표 계산
      double arrowTipX;
      if (arrowDirection == ArrowDirection.bottomRight) {
        arrowTipX = bodyWidth - arrowConfig.position;
      } else if (arrowDirection == ArrowDirection.bottomLeft) {
        arrowTipX = arrowConfig.position;
      } else {
        // bottomCenter인 경우 가로 길이의 정중앙에 위치
        arrowTipX = bodyWidth / 2;
      }

      final double arrowBaseY = bodyHeight; // 박스의 하단 라인
      final double arrowTipY = size.height; // 화살표의 가장 아래 끝점

      // 화살표의 너비 절반
      final double halfWidth = arrowConfig.width / 2;

      // 화살표가 시작되는 왼쪽/오른쪽 상단 점
      final Offset baseLeft = Offset(arrowTipX - halfWidth, arrowBaseY);
      final Offset baseRight = Offset(arrowTipX + halfWidth, arrowBaseY);
      // 화살표의 뾰족한 끝점
      final Offset tipPoint = Offset(arrowTipX, arrowTipY);

      // [둥근 꼭짓점 구현] 꼭짓점 좌우로 얼마나 둥글게 할지 결정하는 수치
      const double r = 2.0;

      // 왼쪽 베이스 라인에서 시작
      path.moveTo(baseLeft.dx, baseLeft.dy);

      // 꼭짓점 근처(왼쪽)까지 선 그리기
      path.lineTo(tipPoint.dx - r,
          tipPoint.dy - (r * (arrowConfig.height / halfWidth)));

      // 꼭짓점을 부드럽게 둥글리기 (베지에 곡선 사용)
      path.quadraticBezierTo(
          tipPoint.dx, // 제어점
          tipPoint.dy,
          tipPoint.dx + r, // 도착점
          tipPoint.dy - (r * (arrowConfig.height / halfWidth)));

      // 오른쪽 베이스 라인으로 선 그리기
      path.lineTo(baseRight.dx, baseRight.dy);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BubblePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.arrowDirection != arrowDirection ||
      oldDelegate.arrowConfig != arrowConfig ||
      oldDelegate.borderRadius != borderRadius;
}
