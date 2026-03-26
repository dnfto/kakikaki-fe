import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';

class CommonOverlay extends StatefulWidget {
  const CommonOverlay({
    super.key,
    this.controller,
    this.overlay,
    required this.child,
  });

  final CommonOverlayController? controller;
  final Widget? overlay;
  final Widget child;

  @override
  State<CommonOverlay> createState() => CommonOverlayState();
}

class CommonOverlayState<T extends CommonOverlay> extends State<T>
    with SingleTickerProviderStateMixin {
  OverlayEntry? _entry;
  CommonOverlayController? _overlayController;
  late AnimationController animationController;

  CommonOverlayController get overlayController =>
      widget.controller ?? (_overlayController ??= CommonOverlayController());
  double get verticalOffset => 30.0;
  bool get preferBelow => false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: Params.animationDuration,
      reverseDuration: Params.animationDurationFast,
      vsync: this,
    );
    overlayController.addListener(handleStatusChanged);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(handleStatusChanged);
      _overlayController?.removeListener(handleStatusChanged);
      overlayController.addListener(handleStatusChanged);
    }
  }

  @override
  void dispose() {
    overlayController.removeListener(handleStatusChanged);
    _entry?.remove();
    _entry?.dispose();
    _overlayController?.dispose();
    animationController.dispose();
    super.dispose();
  }

  void handleStatusChanged() {
    setState(() {});

    switch (overlayController.value) {
      case CommonOverlayStatus.showing:
        return _createEntry();
      case CommonOverlayStatus.hidden:
        return _removeEntry();
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Widget buildOverlay(BuildContext context, Offset target, Widget? overlay) {
    return CommonOverlayWidget(
      animation: CurvedAnimation(
        parent: animationController,
        curve: Params.animationCurve,
      ),
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
      child: overlay,
    );
  }

  void _createEntry() {
    if (!mounted || _entry != null) {
      return;
    }

    final OverlayState overlayState =
        Overlay.of(context, debugRequiredFor: widget);

    final RenderBox box = context.findRenderObject()! as RenderBox;
    final Offset target = box.localToGlobal(
      box.size.center(Offset.zero),
      ancestor: overlayState.context.findRenderObject(),
    );

    _entry = OverlayEntry(
        builder: (BuildContext context) =>
            buildOverlay(context, target, widget.overlay));
    overlayState.insert(_entry!);

    animationController.forward();
  }

  void _removeEntry() => animationController.reverse().whenComplete(() {
        _entry?.remove();
        _entry?.dispose();
        _entry = null;
      });

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/* ------------ Components ------------ */

enum CommonOverlayStatus {
  showing,
  hidden;

  bool get isShowing => this == CommonOverlayStatus.showing;
  bool get isHidden => this == CommonOverlayStatus.hidden;
}

class CommonOverlayController extends ValueNotifier<CommonOverlayStatus> {
  CommonOverlayController({CommonOverlayStatus? status})
      : super(status ?? CommonOverlayStatus.hidden);

  CommonOverlayStatus get status => value;

  void showOverlay() => value = CommonOverlayStatus.showing;

  void hidenOverlay() => value = CommonOverlayStatus.hidden;
}

class CommonOverlayWidget extends StatelessWidget {
  const CommonOverlayWidget({
    super.key,
    required this.animation,
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
    this.child,
  });

  final Animation<double> animation;
  final Offset target;
  final double verticalOffset;
  final bool preferBelow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget result = FadeTransition(
      opacity: animation,
      child: child,
    );

    return Positioned.fill(
      bottom: MediaQuery.maybeViewInsetsOf(context)?.bottom ?? 0.0,
      child: CustomSingleChildLayout(
        delegate: CommonOverlayPositionDelegate(
          target: target,
          verticalOffset: verticalOffset,
          preferBelow: preferBelow,
        ),
        child: Material(type: MaterialType.transparency, child: result),
      ),
    );
  }
}

/// Coppy Material Tooltip [_TooltipPositionDelegate]
class CommonOverlayPositionDelegate extends SingleChildLayoutDelegate {
  CommonOverlayPositionDelegate({
    required this.target,
    required this.verticalOffset,
    required this.preferBelow,
  });

  /// The offset of the target the tooltip is positioned near in the global
  /// coordinate system.
  final Offset target;

  /// The amount of vertical distance between the target and the displayed
  /// tooltip.
  final double verticalOffset;

  /// Whether the tooltip is displayed below its widget by default.
  ///
  /// If there is insufficient space to display the tooltip in the preferred
  /// direction, the tooltip will be displayed in the opposite direction.
  final bool preferBelow;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return positionDependentBox(
      size: size,
      childSize: childSize,
      target: target,
      verticalOffset: verticalOffset,
      preferBelow: preferBelow,
      margin: 0,
    );
  }

  @override
  bool shouldRelayout(CommonOverlayPositionDelegate oldDelegate) {
    return target != oldDelegate.target ||
        verticalOffset != oldDelegate.verticalOffset ||
        preferBelow != oldDelegate.preferBelow;
  }
}

/* ------------ Extension Mixin ------------ */

mixin CommonOverlayUseFocusNode<T extends CommonOverlay>
    on CommonOverlayState<T> {
  FocusNode? _focusNode;
  FocusNode get effectiveFocusNode => _focusNode ??= FocusNode();

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: effectiveFocusNode,
        onFocusChange: (value) {
          if (value) {
            ScrollNotificationObserver.maybeOf(context)
                ?.addListener(handleScrollChanged);
          } else {
            overlayController.hidenOverlay();
            ScrollNotificationObserver.maybeOf(context)
                ?.removeListener(handleScrollChanged);
          }
        },
        child: super.build(context));
  }

  @override
  void handleStatusChanged() {
    if (overlayController.status.isShowing) {
      effectiveFocusNode.requestFocus();
    }
    super.handleStatusChanged();
  }

  void handleScrollChanged(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      overlayController.hidenOverlay();
    }
  }
}

mixin CommonOverlayUseTimer<T extends CommonOverlay> on CommonOverlayState<T> {
  Timer? _dismissTimer;

  Duration get timerDuration => const Duration(seconds: 3);

  @override
  void handleStatusChanged() {
    if (overlayController.status.isShowing) {
      _dismissTimer?.cancel();

      _dismissTimer = Timer(timerDuration, overlayController.hidenOverlay);
    }

    super.handleStatusChanged();
  }

  @override
  void dispose() {
    super.dispose();
    _dismissTimer?.cancel();
    _dismissTimer = null;
  }
}
