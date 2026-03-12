import 'dart:io';
import 'package:kakikaki/core/config/config.dart';
import 'package:dio/dio.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
part 'network_exception.freezed.dart';

/// 네트워크 요청 중 발생하는 예외를 관리하기 위한 커스텀 Exception 클래스
// @freezed: Freezed 어노테이션을 사용해 불변 객체와 다양한 상태를 자동으로 생성
@freezed
class NetworkException with _$NetworkException implements Exception {
  // const NetworkException._(): 프라이빗 생성자. 내부 생성 용도로만 사용되며, 외부에서 직접 인스턴스화하지 못하게 함
  const NetworkException._() : super();

  // unauthorizedException: 인증되지 않은 사용자
  const factory NetworkException.unauthorizedException() =
      _UnauthorizedException;

  // otherException: 기타 예외 상태를 처리하기 위해 예외의 타입을 인자로 받는다.
  const factory NetworkException.otherException(Type type) = _OtherException;

  // formatException: 데이터 형식 오류 발생 시 사용
  const factory NetworkException.formatException() = _FormatException;

  // connectionException: 네트워크 연결 오류가 발생했을 때 사용
  const factory NetworkException.connectionException() = _ConnectionException;

  // maintenanceException: 서버 점검과 같은 예외를 처리
  const factory NetworkException.maintenanceException() = _MaintenanceException;

  // apiException: API 응답에 대한 예외 상태를 처리하며, HTTP 상태 코드와 에러 메시지를 인자로 받는다.
  const factory NetworkException.apiException(
      {int? statusCode, String? message}) = _ApiException;

  // 다양한 예외 상황에 맞는 NetworkException 객체를 반환하는 메서드
  static NetworkException getException(Object error) {
    if (Config.enableLogNetworkException) {
      StackTrace? stackTrace;
      if (error is Error) {
        stackTrace = error.stackTrace;
      }
      Log.e(
        'Error type: ${error.runtimeType}',
        name: 'NetworkException',
        errorObject: error,
        stackTrace: stackTrace,
      );
    }

    /// 예외 타입에 따른 분기 처리
    /// 이미 NetworkException 타입이면 그대로 반환
    if (error is NetworkException) {
      return error;
    } else if (error is SocketException) {
      /// 네트워크 연결 오류
      return const NetworkException.connectionException();
    } else if (error is FormatException || error is TypeError) {
      /// 데이터 형식 오류
      return const NetworkException.formatException();
    } else if (error is DioException) {
      /// Dio 라이브러리의 네트워크 예외
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return const NetworkException.connectionException();

        /// 상태 코드 및 메시지 처리
        case DioExceptionType.badResponse:
          String? message;

          try {
            final json = error.response?.data as Map;

            // error 객체 내부의 message 확인
            if (json['error'] is Map) {
              final errorObj = json['error'] as Map;
              message ??= errorObj['message'] as String?;
              message ??= errorObj['Message'] as String?;
            }

            // 최상위 레벨의 message 확인
            message ??= json['Message'] as String?;
            message ??= json['message'] as String?;
          } catch (e, stackTrace) {
            ErrorReporter.ignoreExpected(
              e,
              stackTrace: stackTrace,
              context: 'NetworkException.message parse',
            );
          }

          message ??= error.message;

          return NetworkException.apiException(
              statusCode: error.response?.statusCode, message: message);

        case DioExceptionType.badCertificate:
        case DioExceptionType.cancel:
        case DioExceptionType.unknown:

          /// 기타 예외 처리
          if (error.error is SocketException) {
            return const NetworkException.connectionException();
          } else if (error.error is FormatException ||
              error.error is TypeError) {
            return const NetworkException.formatException();
          }
      }
    }

    return NetworkException.otherException(error.runtimeType);
  }

  // HTTP 상태 코드 가져오는 getter
  int? get statusCode =>
      whenOrNull(apiException: (statusCode, _) => statusCode);

  // 에러 메시지 가져오는 getter (기본 한국어)
  String? get message => maybeWhen<String?>(
        apiException: (_, message) => message,
        formatException: () => 'Function이 변경되었습니다. 새로운 버전으로 업그레이드 해주세요!',
        connectionException: () => '네트워크 연결이 불안정합니다. 다시 시도해 주세요!',
        orElse: () => '죄송합니다. 에러가 발생했어요. 나중에 다시 시도해 주세요.',
      );

  /// 다국어 지원 에러 메시지
  String? getLocalizedMessage(AppLocalizations l10n) => maybeWhen<String?>(
        apiException: (_, message) => message,
        formatException: () => l10n.network_format_exception,
        connectionException: () => l10n.network_connection_exception,
        orElse: () => l10n.network_error_generic,
      );

  // 네트워크 연결 오류인지 확인하는 메서드
  bool get isConnectionError => maybeWhen(
        connectionException: () => true,
        orElse: () => false,
      );
}
