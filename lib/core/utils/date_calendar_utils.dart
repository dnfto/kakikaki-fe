/// 캘린더 날짜(연·월·일) 비교 — DB는 UTC `timestamptz`, 표시/판단은 기기 로컬 기준
class DateCalendarUtils {
  DateCalendarUtils._();

  /// 두 시각이 **같은 로컬 캘린더 날**인지 (타임존 무관하게 "오늘" 판단용)
  static bool isSameLocalCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Supabase `timestamptz` / ISO 문자열 → 로컬 [DateTime]
  static DateTime? parseTimestamptzToLocal(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value.toLocal();
    final s = value.toString();
    if (s.isEmpty) return null;
    return DateTime.parse(s).toLocal();
  }
}
