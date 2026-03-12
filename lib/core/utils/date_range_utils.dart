import 'package:flutter/material.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/extension/extension.dart';

/// 날짜 범위 선택 결과
class DateRangeSelectionResult {
  final DateTime? rangeStart;
  final DateTime? rangeEnd;

  const DateRangeSelectionResult({
    required this.rangeStart,
    required this.rangeEnd,
  });
}

/// 날짜 범위 선택 관련 유틸리티 함수들
class DateRangeUtils {
  /// 날짜를 yyyy.MM.dd 형식으로 포맷팅
  static String formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  /// 날짜를 yyyy-MM-dd 형식으로 포맷팅
  static String formatDateForStorage(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 날짜 문자열을 DateTime으로 파싱 (yyyy-MM-dd 또는 yyyy.MM.dd 형식 지원)
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      // yyyy.MM.dd 형식을 yyyy-MM-dd로 변환
      final normalizedDate = dateStr.replaceAll('.', '-');
      return DateTime.parse(normalizedDate);
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'DateRangeUtils.parseDate',
      );
      return null;
    }
  }

  /// 날짜 범위 선택 로직 처리
  /// 선택된 날짜에 따라 시작일과 종료일을 업데이트
  /// [allowSameDay]가 false이면 시작일과 종료일이 같을 수 없음
  static DateRangeSelectionResult handleDaySelection({
    required DateTime selectedDay,
    required DateTime? currentRangeStart,
    required DateTime? currentRangeEnd,
    bool allowSameDay = true,
  }) {
    DateTime? newRangeStart = currentRangeStart;
    DateTime? newRangeEnd = currentRangeEnd;

    if (currentRangeStart == null || currentRangeEnd != null) {
      // 새로운 범위 시작
      newRangeStart = selectedDay;
      newRangeEnd = null;
    } else if (selectedDay.isBefore(currentRangeStart)) {
      // 시작일보다 이전 날짜를 선택한 경우
      newRangeStart = selectedDay;
    } else {
      // 종료일 설정
      newRangeEnd = selectedDay;
    }

    return DateRangeSelectionResult(
      rangeStart: newRangeStart,
      rangeEnd: newRangeEnd,
    );
  }

  /// 날짜를 MM.dd 형식으로 포맷팅 (표시용)
  static String formatDateWithoutYear(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}.'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// 두 날짜가 같은 날인지 확인 (시간 제외)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 기간 계산 (몇 박 며칠)
  /// Returns: "N박 M일" 형식의 문자열
  static String calculateDuration(
    BuildContext context, {
    required DateTime start,
    required DateTime end,
  }) {
    final nights = end.difference(start).inDays;
    final days = nights + 1;
    return context.l10n.nights_days(days, nights);
  }
}
