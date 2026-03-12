import 'package:intl/intl.dart';
import 'package:kakikaki/core/extension/num_extension.dart';

/// 자주 사용하는 [String] 유틸리티 클래스
class StringUtils {
  StringUtils._();

  static const needleRegex = r'{#}';
  static const needle = '{#}';
  static final RegExp exp = RegExp(needleRegex);

  /// 문자열 템플릿을 주어진 리스트의 값으로 치환
  static String interpolate(String string, List l) {
    final Iterable<RegExpMatch> matches = exp.allMatches(string);

    assert(l.length == matches.length);

    var i = -1;
    return string.replaceAllMapped(exp, (match) {
      i = i + 1;
      return '${l[i]}';
    });
  }

  /// 숫자를 통화 형식으로 변환
  static String toCurrencyFormat(num money) {
    final oCcy = NumberFormat('#,###');
    return '${oCcy.format(money)}원';
  }

  /// 숫자를 천 단위 형식으로 변환
  static String formatThousands(num number) {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(number);
  }

  /// 숫자를 퍼센트 형식으로 변환 (소수점 자릿수 지정 가능)
  static String formatPercent(num number, [int surplus = 2]) {
    String value = '';
    if (number.isInt) {
      value = number.toInt().toString();
      return value;
    } else {
      value = number.toStringAsFixed(surplus);
      final double checkValue = double.parse(value);
      if (checkValue.isInt) {
        value = checkValue.toInt().toString();
        return value;
      } else {
        return value;
      }
    }
  }

  /// 전화번호 문자열을 형식화
  static String phoneFormatString(String phoneNumber) {
    if (phoneNumber.length > 6) {
      return '${phoneNumber.substring(0, 3)} ${phoneNumber.substring(3, 6)} ${phoneNumber.substring(6, phoneNumber.length)}';
    }
    return phoneNumber;
  }

  /// HTML 태그를 제거한 문자열 반환
  static String customStripHtmlIfNeeded(String text) {
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
  }

  /// HTML 문자열을 일반 문자열로 변환
  static String convertHtmlToString(String text) {
    final cutFirstSpace = text.replaceFirst(RegExp(r'\s+'), ' ');
    final str = customStripHtmlIfNeeded(cutFirstSpace);
    return str;
  }

  /// 주어진 문자열이 URL인지 확인
  static bool isURL(String value) {
    final reg = RegExp(r'^((((H|h)(T|t)|(F|f))(T|t)(P|p)((S|s)?))\://).+');
    return reg.hasMatch(value);
  }
}
