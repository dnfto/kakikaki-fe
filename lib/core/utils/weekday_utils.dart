import 'package:kakikaki/l10n/app_localizations.dart';

/// 요일 관련 유틸리티
class WeekdayUtils {
  /// DateTime.weekday (1=월요일, 7=일요일)를 다국어 요일(월, 화, 수 등)로 변환
  static String getShortWeekdayName(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.weekday_short_monday;
      case DateTime.tuesday:
        return l10n.weekday_short_tuesday;
      case DateTime.wednesday:
        return l10n.weekday_short_wednesday;
      case DateTime.thursday:
        return l10n.weekday_short_thursday;
      case DateTime.friday:
        return l10n.weekday_short_friday;
      case DateTime.saturday:
        return l10n.weekday_short_saturday;
      case DateTime.sunday:
        return l10n.weekday_short_sunday;
      default:
        return '';
    }
  }

  /// DateTime.weekday (1=월요일, 7=일요일)를 다국어 요일(월요일, 화요일 등)로 변환
  /// 설정된 요일 표시 언어에 따라 반환
  /// 주의: table_calendar의 locale이 요일 이름을 결정하므로,
  /// 이 메서드는 동기 버전과 동일하게 동작합니다.
  static Future<String> getFullWeekdayName(
      int weekday, AppLocalizations l10n) async {
    // 현재는 동기 버전과 동일하게 동작
    // 나중에 설정된 언어에 따라 다른 Localizations를 사용하도록 확장 가능
    return getFullWeekdayNameSync(weekday, l10n);
  }

  /// 동기 버전 (기존 호환성 유지)
  static String getFullWeekdayNameSync(int weekday, AppLocalizations l10n) {
    switch (weekday) {
      case DateTime.monday:
        return l10n.weekday_monday;
      case DateTime.tuesday:
        return l10n.weekday_tuesday;
      case DateTime.wednesday:
        return l10n.weekday_wednesday;
      case DateTime.thursday:
        return l10n.weekday_thursday;
      case DateTime.friday:
        return l10n.weekday_friday;
      case DateTime.saturday:
        return l10n.weekday_saturday;
      case DateTime.sunday:
        return l10n.weekday_sunday;
      default:
        return '';
    }
  }
}
