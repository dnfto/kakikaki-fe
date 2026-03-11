import 'package:kakikaki/core/utils/date_time_utils.dart';
import 'package:intl/intl.dart';

extension DateTimeExtesion on DateTime {
  /// Format: yyyy.MM.dd
  String get toDateString => DateTimeUtils.convertToDate(this);

  /// Format: HH:mm:ss
  String get toTimeString => DateTimeUtils.convertToTime(this);

  /// Format: yyyy.MM.dd HH:mm:ss
  String get toDateTimeString => DateTimeUtils.convertToDateTime(this);

  /// Format: HH:mm
  String get toTimeNoSecondString => DateTimeUtils.convertToTimeNoSecond(this);

  /// Format: yyyy.MM.dd HH:mm
  String get toDateTimeNoSecondString {
    return '$toDateString $toTimeNoSecondString';
  }

  // Format: Now, few Seconds Ago, 1 minutes ago, 2 hours ago, 3 days ago,...
  String get toRelativeString => DateTimeUtils.convertToDateRelative(this);
}

extension DateTimeNullExtesion on DateTime? {
  String get toDateString => this?.toDateString ?? '';
  String get toTimeString => this?.toTimeString ?? '';
  String get toDateTimeString => this?.toDateTimeString ?? '';

  String get toTimeNoSecondString => this?.toTimeNoSecondString ?? '';
  String get toDateTimeNoSecondString => this?.toDateTimeNoSecondString ?? '';
}

extension DateFormatExtension on DateFormat {
  DateTime? tryParse(String inputString) {
    try {
      return parse(inputString);
    } on FormatException catch (_) {
      return DateTime.tryParse(inputString);
    }
  }
}
