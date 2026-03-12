import 'formatter_utils.dart';
import 'validate_utils.dart';

/// Common using [DateTime]
class DateTimeUtils {
  const DateTimeUtils._();

  static String convertToDate(DateTime dateTime) {
    return DateTimeFormatter.dateFormatDot.format(dateTime);
  }

  static String convertToTime(DateTime dateTime) {
    return DateTimeFormatter.timeFormat.format(dateTime);
  }

  static String convertToTimeNoSecond(DateTime dateTime) {
    return DateTimeFormatter.timeNoSecondFormat.format(dateTime);
  }

  static String convertToDateTime(DateTime dateTime) {
    return DateTimeFormatter.dateTimeFormatDot.format(dateTime);
  }

  static String convertToDateRelative(
    DateTime dateTime, {
    Duration? formatAfter,
    Duration? timeShowNow = const Duration(seconds: 10),
  }) {
    final DateTime now = DateTime.now();
    // After now
    if (dateTime.isAfter(now)) {
      return convertToDateTime(dateTime);
    }
    // Before formatAfter
    final Duration difference = dateTime.difference(now).abs();
    if (formatAfter != null && difference >= formatAfter) {
      return convertToDateTime(dateTime);
    }
    // Less timeShowNow
    if (timeShowNow != null && difference < timeShowNow) {
      return Validation.l10n.time_now;
    }
    // Defaut
    if (difference < const Duration(minutes: 1)) {
      return Validation.l10n.time_just_now;
    } else if (difference < const Duration(hours: 1)) {
      return Validation.l10n.time_minutes_ago(difference.inMinutes);
    } else if (difference < const Duration(days: 1)) {
      return Validation.l10n.time_hours_ago(difference.inHours);
    } else if (difference < const Duration(days: 30)) {
      return Validation.l10n.time_days_ago(difference.inDays);
    } else if (difference < const Duration(days: 90)) {
      return convertToDate(dateTime);
    } else {
      return convertToDateTime(dateTime);
    }
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);

    return (to.difference(from).inHours / 24).round();
  }

  static int timezoneOffset() {
    return DateTime.now().timeZoneOffset.inHours;
  }

  static DateTime toLocalFromTimestamp({required int utcTimestampMillis}) {
    return DateTime.fromMillisecondsSinceEpoch(utcTimestampMillis, isUtc: true)
        .toLocal();
  }

  static DateTime toUtcFromTimestamp(int localTimestampMillis) {
    return DateTime.fromMillisecondsSinceEpoch(localTimestampMillis).toUtc();
  }

  static DateTime startTimeOfDate() {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  static DateTime? toDateTime(String dateTimeString, {bool isUtc = false}) {
    final dateTime = DateTime.tryParse(dateTimeString);
    if (dateTime != null) {
      if (isUtc) {
        return DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
      }

      return dateTime;
    }

    return null;
  }

  static DateTime? toNormalizeDateTime(String dateTimeString,
      {bool isUtc = false}) {
    final dateTime = DateTime.tryParse('-123450101 $dateTimeString');
    if (dateTime != null) {
      if (isUtc) {
        return DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
      }

      return dateTime;
    }

    return null;
  }

  static DateTime? convertStringToDate(String input) {
    String? dateTimeString;
    List<String> dates = [];

    if (Validation.dateYMD.hasMatch(input)) {
      dates = input.split(RegExp(r'[^0-9]'));
    } else if (Validation.dateDMY.hasMatch(input)) {
      dates = input.split(RegExp(r'[^0-9]')).reversed.toList();
    }

    dates.removeWhere((e) => e.isEmpty);
    if (dates.isNotEmpty && dates[0].length == 2) dates[0] = '20${dates[0]}';
    if (dates.length > 1 && dates[1].length == 1) dates[1] = '0${dates[1]}';
    if (dates.length > 2 && dates[2].length == 1) dates[2] = '0${dates[2]}';
    dateTimeString = dates.take(3).join();

    return DateTime.tryParse(dateTimeString);
  }
}
