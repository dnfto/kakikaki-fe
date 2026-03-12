import 'package:flutter/material.dart';

/// 스크롤 관련 유틸리티 함수들
class ScrollUtils {
  /// 현재 월로 스크롤하는 함수
  ///
  /// [scrollController] 스크롤 컨트롤러
  /// [currentMonthKey] 현재 월 위젯의 GlobalKey
  /// [mounted] 위젯이 마운트되어 있는지 확인하는 함수
  static void scrollToCurrentMonth({
    required ScrollController scrollController,
    required GlobalKey currentMonthKey,
    required bool Function() mounted,
  }) {
    if (!scrollController.hasClients) {
      // 아직 렌더링되지 않았으면 다음 프레임에서 다시 시도
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted()) {
          scrollToCurrentMonth(
            scrollController: scrollController,
            currentMonthKey: currentMonthKey,
            mounted: mounted,
          );
        }
      });
      return;
    }

    // 현재 월이 포함된 인덱스 찾기 (과거 6개월부터 시작하므로 인덱스 6이 현재 월)
    // 각 달력 위젯의 대략적인 높이: 월 헤더(약 52) + 달력(약 328) + SizedBox(height: 16) = 약 396
    const estimatedCalendarHeight = 396.0;
    const currentMonthIndex = 6; // index 0이 _today.month - 6이므로, index 6이 현재 월

    // ensureVisible로 정확히 현재 월로 이동
    final context = currentMonthKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: Duration.zero, // 딜레이 제거
        curve: Curves.easeOut,
        alignment: 0.0, // 화면 상단에 정렬
      );
    } else {
      // 위젯이 아직 렌더링되지 않았으면 대략적인 위치로 즉시 이동
      final targetScroll = estimatedCalendarHeight * currentMonthIndex;
      final maxScroll = scrollController.position.maxScrollExtent;
      final finalScroll = targetScroll.clamp(0.0, maxScroll);
      scrollController.jumpTo(finalScroll);

      // 위젯이 렌더링될 때까지 기다린 후 다시 시도 (딜레이 없이)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted() || !scrollController.hasClients) return;
        final context = currentMonthKey.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: Duration.zero, // 딜레이 제거
            curve: Curves.easeOut,
            alignment: 0.0,
          );
        }
      });
    }
  }
}
