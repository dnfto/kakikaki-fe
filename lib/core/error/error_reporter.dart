import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:kakikaki/core/config/config.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 공통 에러 리포팅 유틸
///
/// - 앱 전역 핸들러(FlutterError, PlatformDispatcher) 설치
/// - 로깅 + Sentry 전송을 한 곳에서 처리
class ErrorReporter {
  ErrorReporter._();

  static void installGlobalHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      report(
        details.exception,
        stackTrace: details.stack,
        context: 'FlutterError.onError',
      );
    };

    PlatformDispatcher.instance.onError =
        (Object error, StackTrace stackTrace) {
      report(
        error,
        stackTrace: stackTrace,
        context: 'PlatformDispatcher.onError',
      );
      return true;
    };
  }

  static Future<void> report(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) async {
    Log.e(
      context == null ? 'Unhandled error' : 'Unhandled error ($context)',
      name: 'ErrorReporter',
      errorObject: error,
      stackTrace: stackTrace,
    );

    if (Config.enableSentry && Config.sentryDsn.isNotEmpty) {
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        hint: context == null ? null : Hint.withMap({'context': context}),
      );
    }
  }

  static void reportSync(
    Object error, {
    StackTrace? stackTrace,
    String? context,
  }) {
    unawaited(report(error, stackTrace: stackTrace, context: context));
  }

  static void ignoreExpected(
    Object error, {
    StackTrace? stackTrace,
    required String context,
  }) {
    Log.w(
      'Ignored expected error ($context): $error',
      name: 'ErrorReporter',
      time: DateTime.now(),
    );

    if (stackTrace != null) {
      Log.d(stackTrace.toString(), name: 'ErrorReporter');
    }
  }
}
