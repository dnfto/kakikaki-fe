import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:flutter/material.dart';

class CommonTabWidget extends StatelessWidget {
  final List<TabItem> tabs;
  final TabController tabController;
  final Widget? belowTabBarWidget;

  const CommonTabWidget({
    super.key,
    required this.tabs,
    required this.tabController,
    this.belowTabBarWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 탭 바
        LayoutBuilder(
          builder: (context, constraints) {
            return TabBar(
              controller: tabController,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: context.palette.primary,
                  width: 2.0,
                ),
              ),
              // labelColor: context.palette.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              unselectedLabelColor: Palette.gray50,
              labelStyle: context.h5_700Style,
              unselectedLabelStyle: context.h5_400Style,
              dividerColor: Palette.gray20, // 선택 안 된 탭 아래 구분선 색상
              tabs: tabs
                  .map((tab) => Tab(
                        text: tab.title,
                      ))
                  .toList(),
            );
          },
        ),
        // 탭바 바로 아래 위젯 (optional)
        if (belowTabBarWidget != null) belowTabBarWidget!,
        // 탭 내용
        Expanded(
          child: AnimatedBuilder(
            animation: tabController,
            builder: (context, child) {
              final currentIndex = tabController.index;
              return tabs[currentIndex].content;
            },
          ),
        ),
      ],
    );
  }
}

class TabItem {
  final String title;
  final Widget content;

  const TabItem({
    required this.title,
    required this.content,
  });
}
