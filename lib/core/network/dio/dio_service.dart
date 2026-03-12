import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// API 요청 취소를 지원하는 Dio 서비스
///
/// 기본 CancelToken을 제공하며, 요청 취소 기능을 지원합니다.
class DioService extends DioForNative {
  DioService([super.baseOptions, Iterable<Interceptor>? interceptors]) {
    if (interceptors != null) {
      this.interceptors.addAll(interceptors);
    }
  }

  /// 기본 CancelToken (취소되면 자동으로 재생성)
  CancelToken? _cancelToken;

  /// 기본 CancelToken 가져오기 (취소된 경우 새로 생성)
  CancelToken get _defaultCancelToken {
    if (_cancelToken == null || _cancelToken!.isCancelled) {
      _cancelToken = CancelToken();
    }
    return _cancelToken!;
  }

  /// 모든 요청 취소
  ///
  /// [cancelToken]이 제공되면 해당 토큰만 취소하고,
  /// null이면 기본 토큰을 취소합니다.
  void cancelRequests({CancelToken? cancelToken}) {
    if (cancelToken != null) {
      cancelToken.cancel('Cancelled');
    } else {
      _defaultCancelToken.cancel('Cancelled');
      _cancelToken = null; // 취소된 토큰은 제거하여 다음에 새로 생성되도록 함
    }
  }

  @override
  Future<Response<T>> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return super.request(
      path,
      data: data,
      queryParameters: queryParameters,
      cancelToken: cancelToken ?? _defaultCancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  @override
  Future<Response<T>> requestUri<T>(
    Uri uri, {
    Object? data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return super.requestUri(
      uri,
      data: data,
      cancelToken: cancelToken ?? _defaultCancelToken,
      options: options,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
}
