import 'package:kakikaki/core/utils/log_utils.dart';

/// Common using log data, log error in class
// mixin: 여러 클래스에 공통 기능을 추가할 수 있는 Dart의 기능
// mixin을 통해 클래스에 중복 없이 로직을 추가할 수 있다.
// 상속과 다르게 여러 클래스에 동시에 적용할 수 있다.

mixin LogMixin on Object {
  /* ───────── 기본 레벨 래핑 ───────── */
  void logD(Object? message, {DateTime? time}) =>
      Log.d(message, name: runtimeType.toString(), time: time);

  void logI(Object? message, {DateTime? time}) =>
      Log.i(message, name: runtimeType.toString(), time: time);

  void logW(Object? message, {DateTime? time}) =>
      Log.w(message, name: runtimeType.toString(), time: time);

  void logE(
    Object? errorMessage, {
    Object? errorObject,
    StackTrace? stackTrace,
    DateTime? time,
  }) =>
      Log.e(
        errorMessage,
        name: runtimeType.toString(),
        errorObject: errorObject,
        stackTrace: stackTrace,
        time: time,
      );

  /* ───────── JSON 전용 헬퍼 ───────── */

  void logJson(Object json, {bool asInfo = true}) {
    final pretty = Log.prettyJson(json);
    asInfo ? logI('\n$pretty') : logD('\n$pretty'); // 용도별 선택
  }

  /* ───────── 임의 레벨 직접 지정 ───────── */

  void logCustom(
    String message, {
    int level = 0,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) =>
      Log.log(
        message,
        name: runtimeType.toString(),
        level: level,
        error: error,
        stackTrace: stackTrace,
        time: time,
      );
}
