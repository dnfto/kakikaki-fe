import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_bloc.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_event.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommonBottomNavBar extends StatelessWidget {
  const CommonBottomNavBar({super.key});

  int _getCurrentIndex(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;

    if (path == '/home' || path == '/') {
      return 0;
    }
    if (path.startsWith('/vocabulary') || path.startsWith('/word')) {
      return 1;
    }
    if (path.startsWith('/study')) {
      return 2;
    }
    if (path.startsWith('/my')) {
      return 3;
    }

    return 0;
  }

  /// 바텀 탭 = 해당 섹션의 **첫 화면**. 동일 경로(`/study`, `/home`)는 BLoC 상태도 초기화합니다.
  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        const HomeRoute().go(context);
        break;
      case 1:
        const VocabularyRoute().go(context);
        break;
      case 2:
        const StudyRoute().go(context);
        getIt<StudyBloc>().add(const StudyEvent.goToFolderSelection());
        break;
      case 3:
        const MyPageRoute().go(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      padding: EdgeInsets.all(context.screenWidth * 0.05),
      color: context.palette.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home,
            label: context.l10n.home_nav_home,
            selected: currentIndex == 0,
            onTap: () => _onTap(context, 0),
          ),
          _NavItem(
            icon: Icons.bookmark,
            label: context.l10n.home_nav_vocabulary,
            selected: currentIndex == 1,
            onTap: () => _onTap(context, 1),
          ),
          _NavItem(
            icon: Icons.menu_book_rounded,
            label: context.l10n.home_nav_study,
            selected: currentIndex == 2,
            onTap: () => _onTap(context, 2),
          ),
          _NavItem(
            icon: Icons.person_4_rounded,
            label: context.l10n.home_nav_my,
            selected: currentIndex == 3,
            onTap: () => _onTap(context, 3),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? context.palette.primary
        : context.isDarkMode
            ? context.palette.onSurface
            : Palette.gray50;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: context.h7_700Style.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
