import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:kakikaki/core/error/error_reporter.dart';

/// TextFormField 검증
class Validation {
  const Validation._();

  static late AppLocalizations l10n;

  // 비밀번호 검증 정규식 (영문 + 숫자 + 특수문자, 10자 이상)
  static final RegExp passwordComplex = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[~!@#$%^&*()_+\-={}|\\:;<>,.?/])[A-Za-z\d~!@#$%^&*()_+\-={}|\\:;<>,.?/]{10,}$');

  // 이메일 정규식
  static final RegExp email = RegExp(r'^(([\w-\.]+@([\w-]+\.)+[\w-]{2,4}))$');
  // dateDMY: DD-MM-YYYY 또는 DD/MM/YYYY 형태
  static final RegExp dateDMY = RegExp(
      r'([0-2][0-9]|3[0-1])?(\\|\/|\-|\.|\,|\s)?(0[1-9]|1[0-2])(\\|\/|\-|\.|\,|\s)([0-9]{4}|[0-9]{2})');
  // dateYMD: YYYY-MM-DD 또는 YYYY/MM/DD 형태
  static final RegExp dateYMD = RegExp(
      r'([0-9]{4}|[0-9]{2})(\\|\/|\-|\.|\,|년|\s)\s?(0?[1-9]|1[0-2])(\\|\/|\-|\.|\,|월|\s)\s?([1-2][0-9]|0?[1-9]|3[0-1])?');
  // 위 두 날짜 형식 중 하나라도 만족하면 true
  static final RegExp date = RegExp('${dateDMY.pattern}|${dateYMD.pattern}');

  // 가격 형식 정규식: 숫자 및 화폐 기호 검증. e.g. ₩1,000, 1,000원
  static final RegExp prices = RegExp(
      r'(^((\d{1,3}[.,])+(\d{1,3})\$|[₩wW]\s?(\d{1,3}[.,])*(\d{1,3})|(\d{1,3}[.,])*(\d{1,3})\s?[원]))');

  //4자리 숫자 검증
  static final RegExp fourDigitNumber = RegExp(r'^\d{4}\$');

  static String? validIdentity(String? value, bool? validId, String? message) {
    if (validId != null && !validId) {
      return message;
    }
    return null;
  }

  static String? validPassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      // return l10n.validation_password_required;
      return null;
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password)) {
      return l10n.validation_password_require_letter;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return l10n.validation_password_require_number;
    }
    if (!RegExp(r'[~!@#\$%^&*()_+\-={}|\\:;<>,.?/]').hasMatch(password)) {
      return l10n.validation_password_require_special;
    }
    if (password.length < 10) {
      return l10n.validation_password_min_length;
    }
    if (!passwordComplex.hasMatch(password)) {
      return l10n.validation_password_invalid_character;
    }
    return null;
  }

  static String? validRePassword(String? value, String oldPass) {
    if (value != oldPass) {
      // 입력값이 기존 비밀번호와 일치하지 않으면 오류 메시지를 반환
      return l10n.validation_rePassword;
    }
    return null;
  }

  static String? validNickname(
      String? value, bool? validNickname, String? message) {
    if (value == null || value.length > 10) {
      return l10n.user_nickname_correct_format(10);
    } else if (validNickname != null && !validNickname) {
      return message;
    }
    return null;
  }

  static String? validEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    } else if (!email.hasMatch(value)) {
      return l10n.validation_email_format;
    }
    return null;
  }

  static String? validSelectImage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validation_select_image;
    }
    return null;
  }

  // 4자리 숫자인지 확인
  static String? validFourDigitNumber(String? value) {
    if (!fourDigitNumber.hasMatch(value ?? '')) {
      return l10n.validation_four_digit_number;
    }
    return null;
  }

  // 날짜가 yyyy-MM-dd 형식인지 확인
  // parseStrict를 사용해 엄격하게 검증
  static bool isDate(String? input) {
    try {
      DateFormat('yyyy-MM-dd').parseStrict(input ?? '');
      return true;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'Validation.isDate',
      );
      return false;
    }
  }
}
