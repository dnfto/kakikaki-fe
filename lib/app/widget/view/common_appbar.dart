import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonAppbar extends StatelessWidget implements PreferredSizeWidget {
  const CommonAppbar({
    super.key,
    this.actions,
    this.bottom,
    this.title,
    this.leading,
    this.leadingWidth,
    this.backgroundColor,
    this.titleSpacing,
  });

  final String? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? leading;
  final double? leadingWidth;
  final Color? backgroundColor;
  final double? titleSpacing;

  @override
  Size get preferredSize =>
      Size.fromHeight(80 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? Palette.black;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppBar(
          backgroundColor: bgColor,
          leading: leading ?? _buildLeadingAppBar(context),
          leadingWidth: leadingWidth ?? context.screenWidth * 0.5,
          toolbarHeight: preferredSize.height,
          centerTitle: false,
          titleSpacing: 0,
          title: title != null
              ? Text(
                  title!,
                  style: context.h2_700Style
                      .copyWith(color: context.palette.onSurface),
                  textScaler: TextScaler.noScaling,
                )
              : null, // title이 null이면 아무 것도 표시하지 않는다.
          actions: actions,
          // forceMaterialTransparency: true,
        ),
        const CommonDivider(),
        if (bottom != null) bottom!,
      ],
    );
  }

  Widget _buildLeadingAppBar(BuildContext context) {
    final ScaffoldState? scaffold = Scaffold.maybeOf(context);

    if (scaffold?.hasDrawer ?? false) {
      return FittedBox(
        fit: BoxFit.contain,
        child: IconButton(
          icon: Icon(
            Icons.menu,
            size: Dimens.appbarLeadingSize,
            color: context.palette.onSurface,
          ),
          padding: Dimens.appbarLeadingPading,
          onPressed: scaffold?.openDrawer,
        ),
      );
    }

    return GestureDetector(
      onTap: () => navigate(
        context,
        path: InitialRoute().location,
        method: NavigationMethod.go,
      ),
      child: CommonIcon.button(
        IconPath.home,
        onPressed: () {},
        fit: BoxFit.fitWidth,
      ),
    );
  }
}

class DefaultCommonAppbar extends StatelessWidget
    implements PreferredSizeWidget {
  const DefaultCommonAppbar({
    super.key,
    this.title = '',
    this.subtitle,
    this.automaticallyImplyLeading = true,
    this.leading,
    this.actions,
    this.rightActions,
    this.bottom,
    this.backgroundColor,
    this.leadingWidth,
    this.titleSpacing,
  });

  final String title;
  final String? subtitle;
  final bool automaticallyImplyLeading;
  final Widget? leading;
  final List<Widget>? actions;
  final List<Widget>? rightActions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final double? leadingWidth;
  final double? titleSpacing;

  @override
  Size get preferredSize => Size.fromHeight(
        Dimens.appbarHeight +
            (subtitle != null ? 20 : 0) +
            (bottom?.preferredSize.height ?? 0),
      );
  @override
  Widget build(BuildContext context) {
    final style = context.h4_700Style.copyWith(color: Palette.white);
    final subtitleStyle = context.h7_400Style.copyWith(color: Palette.white);
    final bgColor = backgroundColor ?? Palette.black;
    final allActions = [...?actions, ...?rightActions];

    return AppBar(
      // 2. 뒤로가기 아이콘 색상 입히기
      iconTheme: const IconThemeData(color: Colors.white),
      automaticallyImplyLeading: leading == null && automaticallyImplyLeading,
      leading: leading,
      leadingWidth: leadingWidth,
      // forceMaterialTransparency: true,
      titleSpacing: titleSpacing ?? context.screenWidth * 0.05,
      backgroundColor: bgColor,
      toolbarHeight: preferredSize.height,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // 왼쪽 정렬
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: style),
          if (subtitle != null) ...[
            const SizedBox(height: 2), // 간격 조절
            Text(subtitle!, style: subtitleStyle),
          ],
        ],
      ),
      actions: allActions.isNotEmpty ? allActions : null,
      bottom: bottom,
    );
  }
}
