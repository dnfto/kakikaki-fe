import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/date_range_utils.dart';
import 'package:kakikaki/core/utils/scroll_utils.dart';
import 'package:flutter/material.dart';
import 'package:kakikaki/core/utils/weekday_utils.dart';

/// 시작일과 종료일을 한 번에 선택할 수 있는 Date Range Picker
/// TableCalendar를 사용한 바텀시트 형태의 달력
class CommonDateRangePicker extends StatelessWidget {
  final TextEditingController startDateController;
  final TextEditingController endDateController;
  final FocusNode? focusNode;
  final String? hintText;
  final Color? borderColor;
  final ValueChanged<DateTimeRange>? onDateRangeSelected;
  final bool showDuration; // "몇박 며칠" 표시 여부
  final bool allowSameDay; // 당일치기 허용 여부 (기본값: true)

  const CommonDateRangePicker({
    super.key,
    required this.startDateController,
    required this.endDateController,
    this.focusNode,
    this.hintText,
    this.borderColor,
    this.onDateRangeSelected,
    this.showDuration = false, // 기본값은 false (이벤트 스팟 등록에서는 안 보여줌)
    this.allowSameDay = true, // 기본값은 true (여정 등록에서는 당일치기 가능)
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _showCalendarBottomSheet(context);
      },
      child: AbsorbPointer(
        child: SizedBox(
          height: 40, // 드롭다운과 같은 높이
          child: TextField(
            readOnly: true,
            focusNode: focusNode,
            controller: TextEditingController(text: _getDisplayText()),
            style: context.h6_400Style,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: 40 * 0.2,
                horizontal: 8,
              ),
              hintText: hintText ?? "기간을 선택해주세요",
              hintStyle: context.h6_400Style.copyWith(
                color: Palette.gray50,
              ),
              filled: true,
              fillColor: Palette.gray10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Palette.gray10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Palette.gray10),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Palette.gray10),
              ),
              prefixIcon: IconButton(
                icon: const Icon(
                  Icons.calendar_today_outlined,
                  size: 24,
                  color: Palette.gray50,
                ),
                onPressed: () async {
                  await _showCalendarBottomSheet(context);
                },
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _hasSelectedDates() {
    return startDateController.text.isNotEmpty &&
        endDateController.text.isNotEmpty;
  }

  String _getDisplayText() {
    if (_hasSelectedDates()) {
      // 날짜 형식 변환 (yyyy-MM-dd -> yyyy.MM.dd)
      final startDate = _formatDisplayDate(startDateController.text);
      final endDate = _formatDisplayDate(endDateController.text);
      return '$startDate ~ $endDate';
    }
    return '';
  }

  String _formatDisplayDate(String dateStr) {
    final date = DateRangeUtils.parseDate(dateStr);
    if (date != null) {
      return DateRangeUtils.formatDate(date);
    }
    return dateStr;
  }

  Future<void> _showCalendarBottomSheet(BuildContext context) async {
    final today = DateTime.now();

    // 기존 선택된 날짜가 있으면 파싱
    final rangeStart = DateRangeUtils.parseDate(startDateController.text);
    final rangeEnd = DateRangeUtils.parseDate(endDateController.text);

    final result = await showModalBottomSheet<DateTimeRange?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CalendarBottomSheet(
        initialStartDate: rangeStart,
        initialEndDate: rangeEnd,
        today: today,
        showDuration: showDuration,
        allowSameDay: allowSameDay,
      ),
    );

    if (result != null) {
      startDateController.text =
          DateRangeUtils.formatDateForStorage(result.start);
      endDateController.text = DateRangeUtils.formatDateForStorage(result.end);

      onDateRangeSelected?.call(result);
    }
  }
}

/// 달력 콘텐츠 위젯 (공통 사용)
class CalendarContent extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime today;
  final bool showDuration; // "몇박 며칠" 표시 여부
  final ValueChanged<DateTimeRange>? onDateRangeSelected; // 전체 페이지 모드에서 사용
  final bool isFullPageMode; // 전체 페이지 모드 여부
  final bool allowSameDay; // 당일치기 허용 여부 (기본값: true)

  const CalendarContent({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    required this.today,
    this.showDuration = false,
    this.onDateRangeSelected,
    this.isFullPageMode = false,
    this.allowSameDay = true, // 기본값은 true (여정 등록에서는 당일치기 가능)
  });

  @override
  State<CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<CalendarContent> {
  late DateTime? _rangeStart;
  late DateTime? _rangeEnd;
  late DateTime _today;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _currentMonthKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _rangeStart = widget.initialStartDate;
    _rangeEnd = widget.initialEndDate;
    _today = widget.today;

    // 현재 월로 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScrollUtils.scrollToCurrentMonth(
        scrollController: _scrollController,
        currentMonthKey: _currentMonthKey,
        mounted: () => mounted,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) async {
    final result = DateRangeUtils.handleDaySelection(
      selectedDay: selectedDay,
      currentRangeStart: _rangeStart,
      currentRangeEnd: _rangeEnd,
      allowSameDay: widget.allowSameDay,
    );

    final newRangeStart = result.rangeStart;
    final newRangeEnd = result.rangeEnd;

    // allowSameDay가 false이고 시작일과 종료일이 같으면 팝업 표시
    if (!widget.allowSameDay &&
        newRangeStart != null &&
        newRangeEnd != null &&
        DateRangeUtils.isSameDay(newRangeStart, newRangeEnd)) {
      // 반환값을 bool로 직접 받아 처리
      final shouldAdjust = await CommonDialogue.showTwoChoiceConfirmDialogue(
        context: context,
        title: context.l10n.calendar_validation_same_day_title,
        content: context.l10n.calendar_validation_same_day_content,
        elevatedButtonText: context.l10n.calendar_date_setting,
      );

      // null 체크와 true/false 여부 확인
      if (shouldAdjust == true) {
        setState(() {
          _rangeStart = newRangeStart;
          _rangeEnd = newRangeEnd.add(const Duration(days: 1));
        });
      } else {
        // 취소했거나 바깥을 눌렀을 때
        setState(() {
          _rangeStart = newRangeStart;
          _rangeEnd = null;
        });
      }
    } else {
      setState(() {
        _rangeStart = newRangeStart;
        _rangeEnd = newRangeEnd;
      });
    }

    // 전체 페이지 모드에서 종료일이 설정되면 콜백 호출
    if (widget.isFullPageMode &&
        _rangeStart != null &&
        _rangeEnd != null &&
        widget.onDateRangeSelected != null) {
      widget.onDateRangeSelected!(
        DateTimeRange(start: _rangeStart!, end: _rangeEnd!),
      );
    }
  }

  void _onConfirm() {
    if (_rangeStart != null && _rangeEnd != null) {
      Navigator.pop(
          context, DateTimeRange(start: _rangeStart!, end: _rangeEnd!));
    }
  }

  Widget _buildCalendar(BuildContext context, DateTime displayMonth) {
    return RangeCalendarWidget(
      displayMonth: displayMonth,
      today: _today,
      rangeStart: _rangeStart,
      rangeEnd: _rangeEnd,
      onDaySelected: _onDaySelected,
    );
  }

  Widget _buildCalendarList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: 18, // 과거 6개월 + 현재 + 미래 12개월 = 총 18개월
      itemBuilder: (context, index) {
        // index 0부터 시작하므로 -6부터 시작
        final displayMonth = DateTime(
          _today.year,
          _today.month + (index - 6),
        );

        // displayMonth가 현재 월과 같은지 확인
        final isCurrentMonth = displayMonth.year == _today.year &&
            displayMonth.month == _today.month;

        return Container(
          key: isCurrentMonth ? _currentMonthKey : null,
          child: _buildCalendar(context, displayMonth),
        );
      },
    );
  }

  Widget _buildDaysOfWeekHeader(BuildContext context) {
    final l10n = context.l10n;

    final weekdays = [
      DateTime.sunday,
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              offset: Offset(0, 6),
              blurRadius: 8,
              color: Palette.black.withExactOpacity(0.08),
            ),
          ],
        ),
        child: ClipRRect(
          // radius 필요 없으면 ClipRRect 자체도 제거 가능
          child: Container(
            color: Palette.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: weekdays.map((weekday) {
                return Expanded(
                  child: Center(
                    child: Text(
                      WeekdayUtils.getShortWeekdayName(weekday, l10n),
                      style: context.h8_400Style.copyWith(
                        color: Palette.gray50,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateDisplay(BuildContext context) {
    if (_rangeStart == null || _rangeEnd == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalMargin,
      ),
      child: Row(
        children: [
          CommonIcon(IconPath.calendar),
          SizedBox(width: 10),
          Text(
            '${DateRangeUtils.formatDateWithoutYear(_rangeStart!)} - ${DateRangeUtils.formatDateWithoutYear(_rangeEnd!)}',
            style: context.h5_600Style,
          ),
          if (widget.showDuration) ...[
            const SizedBox(width: 11),
            Text('|',
                style: context.h7_500Style.copyWith(color: Palette.gray40)),
            const SizedBox(width: 11),
            Text(
              DateRangeUtils.calculateDuration(context,
                  start: _rangeStart!, end: _rangeEnd!),
              style: context.h5_600Style,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 전체 페이지 모드
    if (widget.isFullPageMode) {
      return Column(
        children: [
          _buildDateDisplay(context),
          _buildDaysOfWeekHeader(context),
          Expanded(
            child: _buildCalendarList(context),
          ),
        ],
      );
    }

    // 바텀시트 모드
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Palette.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '기간 선택',
                  style: context.h6_700Style,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // 선택된 날짜 표시
          _buildDateDisplay(context),
          // 달력 (스크롤 가능, 과거 6개월부터 미래 12개월까지)
          Expanded(
            child: _buildCalendarList(context),
          ),
          // 확인 버튼
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_rangeStart != null && _rangeEnd != null)
                    ? _onConfirm
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.primary,
                  foregroundColor: Palette.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  '확인',
                  style: context.h7_700Style.copyWith(color: Palette.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 달력 바텀시트 위젯
class _CalendarBottomSheet extends StatelessWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final DateTime today;
  final bool showDuration;
  final bool allowSameDay;

  const _CalendarBottomSheet({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.today,
    this.showDuration = false,
    this.allowSameDay = true,
  });

  @override
  Widget build(BuildContext context) {
    return CalendarContent(
      initialStartDate: initialStartDate,
      initialEndDate: initialEndDate,
      today: today,
      showDuration: showDuration,
      allowSameDay: allowSameDay,
      isFullPageMode: false,
    );
  }
}
