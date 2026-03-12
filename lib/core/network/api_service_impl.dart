import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/config/config.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:dio/dio.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/core/base/data/dto/base_response.dart';
import 'package:kakikaki/core/network/header_builder.dart';
import 'api_service.dart';
import 'dio/dio_service.dart';
import 'dio/logging_interceptor.dart';
import 'dio/token_interceptor.dart';
import 'network_exception.dart';

@Singleton(as: ApiService)
class ApiServiceImpl implements ApiService {
  ApiServiceImpl({
    this.enableAuth = false,
    this.baseUrl = Config.baseUrl,
    this.timeout,
    HeaderBuilder? headerBuilder,
  }) : _headerBuilderOverride = headerBuilder;

  /// Factory method for creating ApiService with authentication enabled
  @factoryMethod
  factory ApiServiceImpl.create() => ApiServiceImpl(enableAuth: true);

  /// Factory method for creating custom ApiService (baseUrl/headerBuilder 지정 시)
  factory ApiServiceImpl.custom({
    String? baseUrl,
    HeaderBuilder? headerBuilder,
  }) =>
      ApiServiceImpl(
          enableAuth: true, baseUrl: baseUrl, headerBuilder: headerBuilder);

  final bool enableAuth;
  final String? baseUrl;
  final Duration? timeout;

  final HeaderBuilder? _headerBuilderOverride;

  HeaderBuilder get _headerBuilder =>
      _headerBuilderOverride ?? getIt<HeaderBuilder>();

  DioService? _dioService;
  DioService get dioService => _dioService ??= DioService(
        BaseOptions(
            baseUrl: baseUrl ?? '',
            sendTimeout: timeout ?? Config.timeout,
            connectTimeout: timeout ?? Config.timeout,
            receiveTimeout: timeout ?? Config.timeout),
        [
          if (enableAuth) TokenInterceptor(),
          if (Config.enableLogRequestInfo) LoggingInterceptor(),
        ],
      );

  /// 헤더 빌드 (HeaderBuilder 인터페이스 사용)
  Map<String, dynamic> _buildHeaders({
    required bool requiresAuthToken,
    Map<String, dynamic>? customHeaders,
  }) {
    return _headerBuilder.buildHeaders(
      requiresAuthToken: requiresAuthToken,
      customHeaders: customHeaders,
    );
  }

  /// 에러 처리
  Never _handleError(Object error) {
    // 에러 메시지 로깅
    if (error is DioException &&
        error.response != null &&
        error.response!.data != null &&
        error.response!.data['message'] != null) {
      final errorMessage = error.response!.data['message'];
      Log.d('백엔드에서 던져 준 에러: $errorMessage');
    }

    // NetworkException으로 변환하여 throw
    // UI 처리는 상위 레이어(Repository/Bloc)에서 처리하도록 함
    ErrorReporter.ignoreExpected(
      error,
      context: 'ApiServiceImpl.request',
    );
    throw NetworkException.getException(error);
  }

  Future<T> request<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,

    // 커스텀
    required String method,
    required String contentType,
    bool requiresAuthToken = true,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final finalHeaders = _buildHeaders(
        requiresAuthToken: requiresAuthToken,
        customHeaders: headers,
      );

      final Response response = await dioService.request(
        path,
        data: data,
        options: Options(
            method: method, contentType: contentType, headers: finalHeaders),
        queryParameters: queryParameters,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );

      if (converter != null) {
        return converter.call(response.data);
      }

      return response.data as T;
    } catch (error) {
      _handleError(error);
    }
  }

  @override
  void cancelRequests({CancelToken? cancelToken}) =>
      dioService.cancelRequests(cancelToken: cancelToken);

  @override
  Future<T> deleteJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'DELETE',
        contentType: Headers.jsonContentType,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> getJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
    String? contentType,
    Map<String, String>? headers,
  }) async {
    Map<String, String> finalHeaders = {};

    if (headers != null) {
      finalHeaders.addAll(headers);
    }

    return request(
      path,
      method: 'GET',
      contentType: contentType ?? Headers.jsonContentType,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
      converter: converter,
      headers: finalHeaders,
    );
  }

  @override
  Future<T> putJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'PUT',
        contentType: Headers.jsonContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> patchJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'PATCH',
        contentType: Headers.jsonContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> postJson<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  }) =>
      request(path,
          method: 'POST',
          contentType: Headers.jsonContentType,
          data: data,
          queryParameters: queryParameters,
          requiresAuthToken: requiresAuthToken,
          converter: converter,
          headers: headers);

  @override
  Future<T> postFormUrlEncoded<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'POST',
        contentType: Headers.formUrlEncodedContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> postFormData<T>(
    String path, {
    required FormData data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'POST',
        contentType: Headers.multipartFormDataContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  @override
  Future<T> putFormUrlEncoded<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  }) =>
      request(
        path,
        method: 'PUT',
        contentType: Headers.formUrlEncodedContentType,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: converter,
      );

  // BaseResponse 전용 간편 메서드 구현
  @override
  Future<BaseResponse<T>> getBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Json? queryParameters,
    bool requiresAuthToken = true,
    String? contentType,
    Map<String, String>? headers,
  }) =>
      getJson(
        path,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        contentType: contentType,
        headers: headers,
        converter: parseBaseResponse(fromJsonT),
      );

  @override
  Future<BaseResponse<T>> postBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Map<String, dynamic>? headers,
  }) =>
      postJson(
        path,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        headers: headers,
        converter: parseBaseResponse(fromJsonT),
      );

  @override
  Future<BaseResponse<T>> putBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) =>
      putJson(
        path,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: parseBaseResponse(fromJsonT),
      );

  @override
  Future<BaseResponse<T>> patchBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) =>
      patchJson(
        path,
        data: data,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: parseBaseResponse(fromJsonT),
      );

  @override
  Future<BaseResponse<T>> deleteBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) =>
      deleteJson(
        path,
        queryParameters: queryParameters,
        requiresAuthToken: requiresAuthToken,
        converter: parseBaseResponse(fromJsonT),
      );
}
