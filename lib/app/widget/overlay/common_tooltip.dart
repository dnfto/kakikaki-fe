import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:flutter/material.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/extension/extension.dart';

enum TooltipDirection {
  left,
  right,
}

class CommonTooltip extends StatefulWidget {
  final String message;
  final Widget? child; // 직접 만든 위젯을 넣고 싶을 때 사용 (선택)
  final IconData iconData; // 아이콘 모양
  final double iconSize; // 아이콘 크기
  final Color? iconColor; // 아이콘 색상
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final TooltipDirection direction;

  const CommonTooltip({
    super.key,
    required this.message,
    this.child,
    this.iconData = Icons.info_outline, // 기본 아이콘
    this.iconSize = 20.0, // 기본 크기
    this.iconColor, // 기본 색상 (null이면 테마 기본색)
    this.backgroundColor,
    this.textStyle,
    this.direction = TooltipDirection.right,
  });

  @override
  State<CommonTooltip> createState() => _CommonTooltipState();
}

class _CommonTooltipState extends State<CommonTooltip> {
  // ... (중간 변수 및 메서드들은 완벽하므로 그대로 둡니다!) ...
  OverlayEntry? _overlayEntry;
  final GlobalKey _childKey = GlobalKey();
  ScrollController? _scrollController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollController?.removeListener(_updateTooltipPosition);
    try {
      _scrollController = PrimaryScrollController.of(context);
      _scrollController?.addListener(_updateTooltipPosition);
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'CommonTooltip primary scroll controller',
      );
      _scrollController = null;
    }
  }

  void _updateTooltipPosition() {
    if (_overlayEntry != null && mounted) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showTooltip() {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final renderBox =
            _childKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox();

        final Offset widgetOffset = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        final double screenWidth = MediaQuery.of(context).size.width;

        const double verticalGap = 8.0;
        const double arrowOffset = 16.0;

        final double tooltipBottom =
            MediaQuery.of(context).size.height - widgetOffset.dy + verticalGap;

        double? tooltipLeft;
        double? tooltipRight;

        if (widget.direction == TooltipDirection.left) {
          tooltipRight =
              screenWidth - (widgetOffset.dx + (size.width / 2)) - arrowOffset;
        } else {
          tooltipLeft = widgetOffset.dx + (size.width / 2) - arrowOffset;
        }

        return Positioned(
          left: tooltipLeft,
          right: tooltipRight,
          bottom: tooltipBottom,
          child: TapRegion(
            onTapOutside: (PointerDownEvent event) {
              _hideTooltip();
            },
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _hideTooltip,
                child: _buildTooltipContent(screenWidth, arrowOffset),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _overlayEntry != null) {
        _hideTooltip();
      }
    });
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildTooltipContent(double screenWidth, double arrowOffset) {
    // ... (기존 _buildTooltipContent 내용 동일) ...
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenWidth * 0.7,
      ),
      child: BubbleContainer(
        backgroundColor: widget.backgroundColor,
        arrowDirection: widget.direction == TooltipDirection.left
            ? ArrowDirection.bottomRight
            : ArrowDirection.bottomLeft,
        arrowConfig: ArrowConfig(
          width: 10.0,
          height: 9.0,
          position: arrowOffset,
        ),
        borderRadius: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        child: Text(
          widget.message,
          style: widget.textStyle ??
              context.h8_400Style.copyWith(color: Palette.white),
          softWrap: true,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _scrollController?.removeListener(_updateTooltipPosition);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _childKey,
      onTap: () {
        if (_overlayEntry == null) {
          _showTooltip();
        } else {
          _hideTooltip();
        }
      },
      // 여기가 핵심! child가 있으면 child를 보여주고, 없으면 넘겨받은 옵션으로 아이콘을 그립니다.
      child: widget.child ??
          Icon(
            widget.iconData,
            size: widget.iconSize,
            color: widget.iconColor ?? context.palette.onSurface, // 기본색상 지정
          ),
    );
  }
}
