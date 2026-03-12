import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Format string date
class DateTimeFormatter {
  const DateTimeFormatter._();

  // Convert
  static final dateTimeConvert = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS");

  static final dateConvert = DateFormat('yyyy-MM-dd');

  // Format
  static final dateTimeFormatSlash = DateFormat('yyyy/MM/dd HH:mm:ss');

  static final dateFormatSlash = DateFormat('yyyy/MM/dd');

  static final dateTimeFormatHyphen = DateFormat('yyyy-MM-dd HH:mm:ss');

  static final dateFormatHyphen = DateFormat('yyyy-MM-dd');

  static final monthFormatHyphen = DateFormat('yyyy-MM');

  static final dateTimeFormatDot = DateFormat('yyyy.MM.dd HH:mm:ss');

  static final dateFormatDot = DateFormat('yyyy.MM.dd');

  static final timeFormat = DateFormat('HH:mm:ss');

  static final timeNoSecondFormat = DateFormat('HH:mm');
}

/// Using TextField Date
class DateTextFormatter extends TextInputFormatter {
  const DateTextFormatter({this.seperator = '-'});

  final String seperator;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = _format(newValue.text, seperator);
    return newValue.copyWith(text: text, selection: updateCursorPosition(text));
  }

  String _format(String value, String seperator) {
    value = value.replaceAll(seperator, '');
    String newString = '';

    for (int i = 0; i < math.min(value.length, 8); i++) {
      newString += value[i];
      if ((i == 3 || i == 5) && i != value.length - 1) {
        newString += seperator;
      }
    }

    return newString;
  }

  TextSelection updateCursorPosition(String text) {
    return TextSelection.fromPosition(TextPosition(offset: text.length));
  }
}

/// Using TextField Time
class TimeTextFormatter extends TextInputFormatter {
  const TimeTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = _format(newValue.text, ':');
    return newValue.copyWith(text: text, selection: updateCursorPosition(text));
  }

  String _format(String value, String seperator) {
    value = value.replaceAll(seperator, '');
    String newString = '';

    for (int i = 0; i < math.min(value.length, 4); i++) {
      newString += value[i];
      if ((i == 1) && i != value.length - 1) {
        newString += seperator;
      }
    }

    return newString;
  }

  TextSelection updateCursorPosition(String text) {
    return TextSelection.fromPosition(TextPosition(offset: text.length));
  }
}

/// Using TextField phone
class PhoneNumberTextFormatter extends TextInputFormatter {
  const PhoneNumberTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = _format(newValue.text, '-');
    return newValue.copyWith(text: text, selection: updateCursorPosition(text));
  }

  String _format(String value, String seperator) {
    value = value.replaceAll(seperator, '');
    String newString = '';

    for (int i = 0; i < math.min(value.length, 13); i++) {
      newString += value[i];
      if ((i == 2 || i == 6) && i != value.length - 1) {
        newString += seperator;
      }
    }

    return newString;
  }

  TextSelection updateCursorPosition(String text) {
    return TextSelection.fromPosition(TextPosition(offset: text.length));
  }
}

/// 모든 공백 차단 Formatter
class NoWhitespaceFormatter extends TextInputFormatter {
  const NoWhitespaceFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final filteredText = newValue.text.replaceAll(RegExp(r'\s+'), '');
    return newValue.copyWith(
      text: filteredText,
      selection: TextSelection.collapsed(offset: filteredText.length),
    );
  }
}

/// 첫 글자 공백 차단 Formatter
class NoLeadingWhitespaceFormatter extends TextInputFormatter {
  const NoLeadingWhitespaceFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isNotEmpty && text.startsWith(RegExp(r'\s'))) {
      return oldValue;
    }
    return newValue;
  }
}

class InputFormatters {
  const InputFormatters._();

  static NoWhitespaceFormatter get noWhitespace => NoWhitespaceFormatter();
  static NoLeadingWhitespaceFormatter get noLeadingWhitespace =>
      NoLeadingWhitespaceFormatter();
}

class NumberFormatter {
  const NumberFormatter._();

  /// 숫자를 콤마로 구분된 형식으로 변환
  static String formatWithComma(int number) {
    return NumberFormat('#,###').format(number);
  }
}
