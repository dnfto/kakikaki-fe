import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:kakikaki/core/config/config.dart';
import 'package:logger/logger.dart';

class Log {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // 호출 스택 깊이
      errorMethodCount: 8, // 에러 발생 시 출력할 스택 깊이
      lineLength: 100, // 한 줄 길이 제한
      colors: true, // 색상 적용 여부
      printEmojis: true, // 이모지 사용 여부
    ),
  );

  // Config.enableGeneralLog 값이 true일 때만 로그 출력
  static bool get _enableLog => Config.enableGeneralLog;

  /// 디버그 로그 출력 (Debug)
  static void d(
    Object? message, {
    String? name,
    DateTime? time,
    int level = 0,
  }) {
    if (_enableLog) {
      final logMessage = _formatMessage(message, name);
      _logger.d(logMessage);
      _logToDevConsole(
        logMessage,
        name,
        time,
        null,
        null,
        level,
      );
    }
  }

  /// 정보 로그 출력 (Info)
  static void i(
    Object? message, {
    String? name,
    DateTime? time,
    int level = 500,
  }) {
    if (_enableLog) {
      final logMessage = _formatMessage(message, name);
      _logger.i(logMessage);
      _logToDevConsole(
        logMessage,
        name,
        time,
        null,
        null,
        level,
      );
    }
  }

  /// 경고 로그 출력 (Warning)
  static void w(
    Object? message, {
    String? name,
    DateTime? time,
    int level = 800,
  }) {
    if (_enableLog) {
      final logMessage = _formatMessage(message, name);
      _logger.w(logMessage);
      _logToDevConsole(
        logMessage,
        name,
        time,
        null,
        null,
        level,
      );
    }
  }

  /// 에러 로그 출력 (Error)
  static void e(
    Object? errorMessage, {
    String? name,
    Object? errorObject,
    StackTrace? stackTrace,
    DateTime? time,
    int level = 1000,
  }) {
    if (_enableLog) {
      final logMessage = _formatMessage(
        errorMessage,
        name,
      );
      _logger.e(
        logMessage,
        error: errorObject,
        stackTrace: stackTrace,
      );
      _logToDevConsole(
        logMessage,
        name,
        time,
        errorObject,
        stackTrace,
        level,
      );
    }
  }

  /// JSON 포맷팅 메서드 (Pretty JSON)
  static String prettyJson(Object json) {
    if (!Config.isPrettyJson) {
      return json.toString();
    }
    try {
      final encoder = JsonEncoder.withIndent('\t');
      if (json is Map<String, dynamic> || json is List<dynamic>) {
        return encoder.convert(json);
      }
      return json.toString();
    } catch (e) {
      return 'Invalid JSON: $e';
    }
  }

  /// 공통 로그 처리 메서드: 모든 로그 출력의 기반 메서드가 된다.
  static void log(
    String message, {
    String? name,
    int level = 0,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
    int? sequenceNumber,
    Zone? zone,
  }) {
    if (_enableLog) {
      final logMessage = _formatMessage(message, name);
      _logger.log(Level.debug, logMessage,
          error: error, stackTrace: stackTrace);
      _logToDevConsole(
        logMessage,
        name,
        time,
        error,
        stackTrace,
        level,
        sequenceNumber,
        zone,
      );
    }
  }

  /// `dev.log()`를 활용하여 기존 기능을 유지하는 보조 함수
  static void _logToDevConsole(
    String message,
    String? name, [
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
    int level = 0,
    int? sequenceNumber,
    Zone? zone,
  ]) {
    final logTime = time ?? DateTime.now();
    dev.log(
      message,
      name: name ?? '',
      time: logTime,
      level: level,
      error: error,
      stackTrace: stackTrace,
      sequenceNumber: sequenceNumber,
      zone: zone,
    );
  }

  /// 로그 메시지를 일관되게 포맷하는 보조 함수
  static String _formatMessage(Object? message, String? name) {
    return name != null ? '[$name] $message' : '$message';
  }
}
