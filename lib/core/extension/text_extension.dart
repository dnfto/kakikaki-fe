import 'package:flutter/widgets.dart';
import 'package:kakikaki/core/utils/string_utils.dart';

extension TextStyleExtension on TextStyle {
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
}

extension StringExtension on String? {
  /// 앞과 뒤의 공백을 제거하고 중복된 공백을 제거
  /// Example: '  Hello   World  ' -> 'Hello World'
  String? trimExtra() => this?.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// null이거나 비어있는 문자열일 때 기본값 반환
  /// Example: null.or('기본값') -> '기본값'
  ///          ''.or('기본값')   -> '기본값'
  ///          'Hi'.or('기본값') -> 'Hi'
  String or(String defaultValue) =>
      (this?.trim().isNotEmpty == true) ? this!.trim() : defaultValue;

  /// null 또는 빈 문자열 또는 공백 문자열이면 false
  bool get isNotNullOrEmpty => this?.trim().isNotEmpty == true;

  /// Sort ASC for string
  int compareASC(String? text, {bool caseSensitive = false}) {
    if (caseSensitive) {
      return this?.compareTo(text ?? '') ?? 0;
    }
    return this?.toLowerCase().compareTo(text?.toLowerCase() ?? '') ?? 0;
  }

  /// Sort DESC for string
  int compareDESC(String? text, {bool caseSensitive = false}) {
    return -compareASC(text, caseSensitive: caseSensitive);
  }

  /// 핸드폰 포메팅
  /// Example: '01012345678' -> '010-1234-5678'
  String get toPhoneString => StringUtils.phoneFormatString(this ?? '');
}
