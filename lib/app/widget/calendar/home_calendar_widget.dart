import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakikaki/features/my/domain/enums/calendar_enums.dart';

/// 홈 화면에서 사용하는 달력 위젯
class HomeCalendarWidget extends StatefulWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback? onMonthChanged;
  final Set<DateTime> writtenDates; // 일기가 작성된 날짜 목록

  const HomeCalendarWidget({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.today,
    required this.onDaySelected,
    this.onMonthChanged,
    this.writtenDates = const {},
  });

  @override
  State<HomeCalendarWidget> createState() => _HomeCalendarWidgetState();
}

class _HomeCalendarWidgetState extends State<HomeCalendarWidget> {
  static const String _weekdayLanguageKey = 'calendar_weekday_language';
  static const String _startingDayKey = 'calendar_starting_day';

  // 원시 타입(String, int) 대신 안전한 Enum 타입으로 변수 선언
  WeekdayLanguage _weekdayLanguage = WeekdayLanguage.ko;
  CalendarStartingDay _startingDay = CalendarStartingDay.sunday;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 문자열로 꺼내기 (기본값 설정)
    final savedLangName =
        prefs.getString(_weekdayLanguageKey) ?? WeekdayLanguage.ko.name;
    final savedDayName =
        prefs.getString(_startingDayKey) ?? CalendarStartingDay.sunday.name;

    // 2. 문자열을 Enum 객체로 변환
    final langEnum = WeekdayLanguage.values.firstWhere(
      (e) => e.name == savedLangName,
      orElse: () => WeekdayLanguage.ko,
    );

    final dayEnum = CalendarStartingDay.values.firstWhere(
      (e) => e.name == savedDayName,
      orElse: () => CalendarStartingDay.sunday,
    );

    if (mounted) {
      setState(() {
        _weekdayLanguage = langEnum;
        _startingDay = dayEnum;
      });
    }
  }

  @override
  void didUpdateWidget(HomeCalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 월 헤더 및 네비게이션
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                '${widget.focusedDay.year}년 ${widget.focusedDay.month}월',
                style: context.h6_700Style,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  final prevMonth = DateTime(
                    widget.focusedDay.year,
                    widget.focusedDay.month - 1,
                  );
                  widget.onDaySelected(prevMonth);
                  widget.onMonthChanged?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  final nextMonth = DateTime(
                    widget.focusedDay.year,
                    widget.focusedDay.month + 1,
                  );
                  widget.onDaySelected(nextMonth);
                  widget.onMonthChanged?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // 달력
        TableCalendar(
          firstDay: DateTime(2000),
          lastDay: DateTime(2100),
          focusedDay: widget.focusedDay,
          selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
          currentDay: widget.today,
          onDaySelected: (selectedDay, focusedDay) {
            widget.onDaySelected(selectedDay);
          },
          onPageChanged: (focusedDay) {
            widget.onDaySelected(focusedDay);
          },
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: _startingDay == CalendarStartingDay.sunday
              ? StartingDayOfWeek.sunday
              : StartingDayOfWeek.monday,
          headerVisible: false,
          daysOfWeekHeight: 40,
          rowHeight: 56,
          locale: _weekdayLanguage.code,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: context.h8_400Style.copyWith(
              color: Palette.gray50,
            ),
            weekendStyle: context.h8_400Style.copyWith(
              color: context.palette.primary,
            ),
          ),
          calendarStyle: CalendarStyle(
            defaultTextStyle: context.h7_400Style,
            weekendTextStyle: context.h7_400Style.copyWith(
              color: context.palette.primary,
            ),
            todayDecoration: BoxDecoration(
              color: context.palette.primary.withExactOpacity(0.2),
              shape: BoxShape.circle,
            ),
            todayTextStyle: context.h7_400Style,
            selectedDecoration: BoxDecoration(
              color: context.palette.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: context.h7_700Style.copyWith(
              color: Palette.white,
            ),
            outsideTextStyle: context.h7_400Style.copyWith(
              color: Palette.gray30,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, date, focusedDay) {
              return _buildDayCell(context, date, focusedDay);
            },
            todayBuilder: (context, date, focusedDay) {
              return _buildDayCell(context, date, focusedDay, isToday: true);
            },
            selectedBuilder: (context, date, focusedDay) {
              return _buildDayCell(context, date, focusedDay, isSelected: true);
            },
            outsideBuilder: (context, date, focusedDay) {
              return _buildDayCell(context, date, focusedDay, isOutside: true);
            },
          ),
        ),
      ],
    );
  }

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime date,
    DateTime focusedDay, {
    bool isToday = false,
    bool isSelected = false,
    bool isOutside = false,
  }) {
    final normalizedDay = DateTime(date.year, date.month, date.day);
    final hasWritten = widget.writtenDates
        .any((writtenDate) => isSameDay(normalizedDay, writtenDate));

    final isSelectedDay = isSameDay(widget.selectedDay, date);
    final isTodayDay = isSameDay(widget.today, date);

    Color textColor = isOutside
        ? Palette.gray30
        : (date.weekday == DateTime.sunday || date.weekday == DateTime.saturday)
            ? context.palette.primary
            : Colors.black;

    if (isSelectedDay) {
      textColor = Colors.white;
    }

    // 💡 꼼수(Stack negative margin)를 버리고, 안전하게 Column으로 56px 안에 차곡차곡 쌓습니다.
    return SizedBox(
      height: 56, // TableCalendar의 rowHeight와 동일한 높이 제공
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. 날짜 및 선택/오늘 동그라미 배경
          Container(
            width: 36,
            height: 36,
            decoration: isSelectedDay
                ? BoxDecoration(
                    color: context.palette.primary,
                    shape: BoxShape.circle,
                  )
                : isTodayDay
                    ? BoxDecoration(
                        color: context.palette.primary.withExactOpacity(0.2),
                        shape: BoxShape.circle,
                      )
                    : null,
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: context.h7_400Style.copyWith(
                color: textColor,
                fontWeight: isSelectedDay ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),

          // 2. 동그라미와 하트 사이의 간격 (원하는 만큼 조절 가능)
          const SizedBox(height: 2),

          // 3. 하트 영역 고정
          // (영역 높이를 8로 고정해두면, 하트가 없는 날짜도 레이아웃이 위아래로 흔들리지 않습니다!)
          SizedBox(
            height: 8,
            child: hasWritten
                ? Icon(
                    Icons.favorite,
                    size: 8,
                    color: context.palette.primary,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
