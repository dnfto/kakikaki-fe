import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

import 'package:table_calendar/table_calendar.dart';

/// 날짜 범위 선택을 위한 공통 달력 위젯
class RangeCalendarWidget extends StatelessWidget {
  final DateTime displayMonth;
  final DateTime today;
  final DateTime? rangeStart;
  final DateTime? rangeEnd;
  final OnDaySelected onDaySelected;

  const RangeCalendarWidget({
    super.key,
    required this.displayMonth,
    required this.today,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 월 헤더
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.screenWidth * 0.05,
            vertical: 16,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${displayMonth.year}년 ${displayMonth.month}월',
              style: context.h6_700Style.copyWith(color: Palette.gray70),
            ),
          ),
        ),

        // 달력
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: displayMonth,
          currentDay: today,
          rangeStartDay: rangeStart,
          rangeEndDay: rangeEnd,
          rangeSelectionMode: RangeSelectionMode.enforced,
          onDaySelected: onDaySelected,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerVisible: false,
          daysOfWeekHeight: 40,
          rowHeight: 48,
          availableGestures: AvailableGestures.none,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: context.h8_400Style.copyWith(
              color: Palette.gray50,
            ),
            weekendStyle: context.h8_400Style.copyWith(
              color: Palette.gray50,
            ),
          ),
          calendarStyle: CalendarStyle(
            // 기본 날짜 스타일
            defaultTextStyle: context.h7_400Style,
            weekendTextStyle: context.h7_400Style,
            // 오늘 날짜 스타일
            todayDecoration: BoxDecoration(
              color: context.palette.primary.withExactOpacity(0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: context.h7_400Style,
            // 선택된 날짜 스타일
            selectedDecoration: BoxDecoration(
              color: context.palette.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: context.h7_700Style.copyWith(
              color: Palette.white,
            ),
            // 범위 시작/종료 스타일
            rangeStartDecoration: BoxDecoration(
              color: context.palette.primary,
              shape: BoxShape.circle,
            ),
            rangeStartTextStyle: context.h7_700Style.copyWith(
              color: Palette.white,
            ),
            rangeEndDecoration: BoxDecoration(
              color: context.palette.primary,
              shape: BoxShape.circle,
            ),
            rangeEndTextStyle: context.h7_700Style.copyWith(
              color: Palette.white,
            ),
            // 범위 내 날짜 스타일 (첫날/마지막날 제외하고는 원 없음)
            withinRangeDecoration: const BoxDecoration(),
            withinRangeTextStyle: context.h7_400Style,
            // 다른 월 날짜 스타일
            outsideTextStyle: context.h7_400Style.copyWith(
              color: Palette.gray30,
            ),
            // 마커 제거
            markerDecoration: const BoxDecoration(),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}
