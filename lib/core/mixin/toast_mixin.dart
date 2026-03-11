import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/network/network_exception.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

/// 앱에 토스트 메시지를 띄우는 ToastMixin
///
/// * API 호출이 실패했을 때
/// * 앱 실행 function이 실패했을 때
//
mixin ToastMixin on Object {
  Future<bool?> addToastMessage(
    String message, {
    // 출력할 메시지
    ToastGravity? gravity, // 토스트 메시지의 위치
    Toast? toastLength, // 토스트 메시지의 길이 (짧게 or 길게)
    double? fontSize, // 메시지 폰트 크기
    Color? textColor, // 메시지 텍스트 색상
    Color? backgroundColor, // 메시지 배경 색상
  }) {
    return Fluttertoast.showToast(
      msg: message,
      gravity: gravity ?? ToastGravity.BOTTOM,
      toastLength: toastLength ?? Toast.LENGTH_SHORT,
      timeInSecForIosWeb: 1,
      textColor: textColor ?? Palette.white,
      backgroundColor: backgroundColor ?? Palette.gray90,
      fontSize: fontSize ?? 12,
    );
  }

  // 예외 객체를 받아 예외 상태를 토스트 메시지로 출력
  // NetworkException을 특별하게 처리하며, 메시지를 가져와 사용자에게 출력
  Future<bool?> addToastException(
    Exception exception, {
    ToastGravity? gravity,
    Toast? toastLength,
    double? fontSize,
    Color? textColor,
    Color? backgroundColor,
  }) {
    if (exception is NetworkException) {
      final l10n = lookupAppLocalizations(getIt<GlobalBloc>().state.locale);
      final message =
          exception.getLocalizedMessage(l10n) ?? exception.toString();

      return addToastMessage(
        message,
        gravity: gravity,
        toastLength: toastLength = Toast.LENGTH_SHORT,
        textColor: textColor = Palette.white,
        backgroundColor: backgroundColor = Palette.gray90,
        fontSize: fontSize ?? 12,
      );
    }

    return addToastMessage(exception.toString());
  }
}
