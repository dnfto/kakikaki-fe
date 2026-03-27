import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/enums/primary_color_type.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';

class ColorSettingsPage extends StatefulWidget {
  const ColorSettingsPage({super.key});

  @override
  State<ColorSettingsPage> createState() => _ColorSettingsPageState();
}

class _ColorSettingsPageState
    extends BaseScaffoldPageState<ColorSettingsPage, MyBloc, MyState> {
  _ColorSettingsPageState()
      : super(
            horizontalMargin: 0,
            verticalMargin: 0,
            isBottomNavigationBar: false);

  @override
  String get appBarTitle => context.l10n.settings_theme_title;
  @override
  Widget buildPage(BuildContext context, MyState state) {
    final globalBloc = context.watch<GlobalBloc>();
    final currentColorType =
        globalBloc.state.primaryColorType.toPrimaryColorType();
    // final currentThemeMode = globalBloc.state.themeModeEnum;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // 테마 색상 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              context.l10n.settings_theme_colors,
              style: context.h6_700Style,
            ),
          ),
          const SizedBox(height: 12),
          _buildColorOption(
            context,
            title: context.l10n.settings_theme_sky_blue,
            colorType: PrimaryColorType.skyBlue,
            color: Palette.skyBlue50,
            isSelected: currentColorType == PrimaryColorType.skyBlue,
            onTap: () => _changeColor(context, PrimaryColorType.skyBlue),
          ),
          _buildColorOption(
            context,
            title: context.l10n.settings_theme_pink,
            colorType: PrimaryColorType.pink,
            color: Palette.pink50,
            isSelected: currentColorType == PrimaryColorType.pink,
            onTap: () => _changeColor(context, PrimaryColorType.pink),
          ),
          _buildColorOption(
            context,
            title: context.l10n.settings_theme_blue,
            colorType: PrimaryColorType.blue,
            color: Palette.blue50,
            isSelected: currentColorType == PrimaryColorType.blue,
            onTap: () => _changeColor(context, PrimaryColorType.blue),
          ),
          _buildColorOption(
            context,
            title: context.l10n.settings_theme_red,
            colorType: PrimaryColorType.red,
            color: Palette.red50,
            isSelected: currentColorType == PrimaryColorType.red,
            onTap: () => _changeColor(context, PrimaryColorType.red),
          ),
          _buildColorOption(
            context,
            title: context.l10n.settings_theme_orange,
            colorType: PrimaryColorType.orange,
            color: Palette.orange50,
            isSelected: currentColorType == PrimaryColorType.orange,
            onTap: () => _changeColor(context, PrimaryColorType.orange),
          ),
          // const SizedBox(height: 32),
          // // 다크모드 섹션
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 20),
          //   child: Text(
          //     '다크모드',
          //     style: context.h6_700Style,
          //   ),
          // ),
          // const SizedBox(height: 12),
          // _buildThemeModeOption(
          //   context,
          //   title: '라이트 모드',
          //   themeMode: ThemeMode.light,
          //   isSelected: currentThemeMode == ThemeMode.light,
          //   onTap: () => _changeThemeMode(context, ThemeMode.light),
          // ),
          // _buildThemeModeOption(
          //   context,
          //   title: '다크 모드',
          //   themeMode: ThemeMode.dark,
          //   isSelected: currentThemeMode == ThemeMode.dark,
          //   onTap: () => _changeThemeMode(context, ThemeMode.dark),
          // ),
          // _buildThemeModeOption(
          //   context,
          //   title: '시스템 설정',
          //   themeMode: ThemeMode.system,
          //   isSelected: currentThemeMode == ThemeMode.system,
          //   onTap: () => _changeThemeMode(context, ThemeMode.system),
          // ),
          // const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildColorOption(
    BuildContext context, {
    required String title,
    required PrimaryColorType colorType,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withExactOpacity(0.1) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Palette.gray20,
                  width: isSelected ? 3 : 1,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: context.h6_400Style,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context, {
    required String title,
    required ThemeMode themeMode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    IconData iconData;
    switch (themeMode) {
      case ThemeMode.light:
        iconData = Icons.light_mode_outlined;
        break;
      case ThemeMode.dark:
        iconData = Icons.dark_mode_outlined;
        break;
      case ThemeMode.system:
        iconData = Icons.brightness_auto_outlined;
        break;
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Palette.gray10 : null,
        ),
        child: Row(
          children: [
            Icon(iconData, size: 24, color: Palette.gray90),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: context.h6_400Style,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Palette.skyBlue50,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _changeColor(BuildContext context, PrimaryColorType colorType) {
    context.read<GlobalBloc>().add(GlobalEvent.changePrimaryColor(colorType));
  }

  void _changeThemeMode(BuildContext context, ThemeMode themeMode) {
    context.read<GlobalBloc>().add(GlobalEvent.changeTheme(themeMode));
  }
}
