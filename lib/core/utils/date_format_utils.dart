import 'package:kakikaki/l10n/app_localizations.dart';

/// 날짜 포맷 관련 유틸리티
class DateFormatUtils {
  /// 월과 일을 다국어로 포맷 (예: "12월 1일", "December 1")
  static String formatMonthDay({
    required int month,
    required int day,
    required AppLocalizations l10n,
  }) {
    // 한국어일 경우: "12월 1일"
    if (l10n.localeName == 'ko') {
      return '$month월 $day일';
    }
    // 영어일 경우: "December 1"
    // 영어는 월 이름을 사용
    if (month >= 1 && month <= 12) {
      final monthNames = [
        l10n.month_january,
        l10n.month_february,
        l10n.month_march,
        l10n.month_april,
        l10n.month_may,
        l10n.month_june,
        l10n.month_july,
        l10n.month_august,
        l10n.month_september,
        l10n.month_october,
        l10n.month_november,
        l10n.month_december,
      ];
      return l10n.date_format_month_day(monthNames[month - 1], day);
    }

    return '$month/$day';
  }
}
