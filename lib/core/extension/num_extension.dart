import 'package:kakikaki/core/utils/string_utils.dart';

/// 숫자 확장 함수
extension NumExtension on num {
  /// 텍스트 형식으로 변환 '#,### 원'
  String get toCurrencyFormat => StringUtils.toCurrencyFormat(this);

  /// 텍스트 형식으로 변환 '#,###'
  String get toThousands => StringUtils.formatThousands(this);

  /// 텍스트 형식으로 변환 '#,###'
  String toPercent([int surplus = 2]) =>
      StringUtils.formatPercent(this, surplus);

  /// 정수인지 여부 반환
  bool get isInt => (this % 1) == 0;
}

/// 숫자 연산 확장 함수
extension NumExtensions on num {
  /// 숫자 더하기
  num plus(num other) {
    return this + other;
  }

  /// 숫자 빼기
  num minus(num other) {
    return this - other;
  }

  /// 숫자 곱하기
  num times(num other) {
    return this * other;
  }

  /// 숫자 나누기
  num div(num other) {
    return this / other;
  }
}

/// 정수 연산 확장 함수
extension IntExtensions on int {
  /// 정수 더하기
  int plus(int other) {
    return this + other;
  }

  /// 정수 빼기
  int minus(int other) {
    return this - other;
  }

  /// 정수 곱하기
  int times(int other) {
    return this * other;
  }

  /// 정수 나누기
  double div(int other) {
    return this / other;
  }

  /// 정수 나누기 (몫 반환)
  int truncateDiv(int other) {
    return this ~/ other;
  }
}

/// 실수 연산 확장 함수
extension DoubleExtensions on double {
  /// 실수 더하기
  double plus(double other) {
    return this + other;
  }

  /// 실수 빼기
  double minus(double other) {
    return this - other;
  }

  /// 실수 곱하기
  double times(double other) {
    return this * other;
  }

  /// 실수 나누기
  double div(double other) {
    return this / other;
  }
}
