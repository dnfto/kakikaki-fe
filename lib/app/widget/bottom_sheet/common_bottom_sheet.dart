import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

extension CommonBottomSheetExtension on BuildContext {
  Future<int?> showOptionBottomSheet(Iterable<Widget> options,
      {int? indexSelected}) {
    return showModalCommonBottomSheet(CommonBottomSheet.option(
        options: options, indexSelected: indexSelected));
  }

  Future<T?> showModalCommonBottomSheet<T>(
    CommonBottomSheet bottomSheet, {
    bool useSafeArea = true,
    Color? barrierColor,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      elevation: 0,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: isDismissible,
      shape: RoundedRectangleBorder(
        borderRadius: Dimens.bottomSheetRadius,
        side: BorderSide(color: palette.shadow, width: 0.25),
      ),
      builder: (BuildContext context) => bottomSheet,
    );
  }

  PersistentBottomSheetController showCommonBottomSheet(
      CommonBottomSheet bottomSheet) {
    return showBottomSheet(
      context: this,
      elevation: 0,
      enableDrag: true,
      shape: RoundedRectangleBorder(
        borderRadius: Dimens.bottomSheetRadius,
        side: BorderSide(color: palette.shadow, width: 0.25),
      ),
      builder: (BuildContext context) => bottomSheet,
    );
  }
}

class CommonBottomSheet extends StatelessWidget {
  const CommonBottomSheet({
    super.key,
    this.title,
    this.padding = const EdgeInsets.only(top: 16),
    this.heightFactor,
    this.resizeToAvoidBottomInset = true,
    this.isDragHandle = false,
    required this.child,
  });

  CommonBottomSheet.option({
    super.key,
    this.title,
    int? indexSelected,
    EdgeInsetsGeometry padding = const EdgeInsets.all(10),
    this.heightFactor,
    this.resizeToAvoidBottomInset = true,
    this.isDragHandle = false,
    double gap = Dimens.bottomSheetGap,
    required Iterable<Widget> options,
  })  : padding = EdgeInsets.zero,
        child = Builder(builder: (BuildContext context) {
          return DefaultTextStyle.merge(
            style: context.h6_400Style,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.symmetric(vertical: padding.vertical)
                  .add(context.mediaQueryViewPadding),
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) => GestureDetector(
                onTap: () => Navigator.of(context).pop(index),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: padding.horizontal, vertical: gap / 2),
                  color: indexSelected == index
                      ? context.colorScheme.primary
                      : context.palette.surface,
                  child: options.elementAt(index),
                ),
              ),
            ),
          );
        });

  final String? title;
  final EdgeInsetsGeometry padding;
  final double? heightFactor;
  final bool resizeToAvoidBottomInset;
  final bool isDragHandle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData queryData = MediaQuery.of(context);
    final viewInsetHeight = resizeToAvoidBottomInset
        ? queryData.viewInsets.bottom + queryData.viewInsets.top
        : 0;
    final viewInsetWidth =
        queryData.viewInsets.left + queryData.viewInsets.right;

    return GestureDetector(
      onTap: FocusScope.of(context).unfocus,
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Drag handle
            if (isDragHandle)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.palette.shadow,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

            /// Build title
            if (title != null)
              Padding(
                padding: padding,
                child: Text(
                  title!,
                  style: context.h3_700Style.copyWith(
                    color: context.palette.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),

            /// Build body
            DefaultTextStyle(
              style: context.h6_400Style.copyWith(
                color: context.palette.onSurface,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (queryData.size.height * (heightFactor ?? 0.9)) -
                      viewInsetHeight,
                  maxWidth: queryData.size.width - viewInsetWidth,
                ),
                child: child,
              ),
            ),

            /// Bottom spacing (with safe area)
            SizedBox(
              height:
                  context.screenHeight * 0.05 + queryData.viewPadding.bottom,
            ),
          ],
        ),
      ),
    );
  }
}
