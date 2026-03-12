import 'package:dio/dio.dart';
import 'package:kakikaki/core/base/base.dart';

typedef Json = Map<String, dynamic>;
typedef FromJson<T> = T Function(Json json);
typedef ToJson<T> = Json Function(T data);
typedef Converter<T> = T Function(dynamic data);
typedef Progress = void Function(int count, int total);

/// HTTP networking interface
abstract class ApiService {
  const ApiService();

  void cancelRequests({CancelToken? cancelToken});

  Future<T> deleteJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  Future<T> getJson<T>(
    String path, {
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
    String? contentType,
    Map<String, String>? headers,
  });

  Future<T> putJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  Future<T> patchJson<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  Future<T> postJson<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
    Map<String, dynamic>? headers,
  });

  Future<T> postFormUrlEncoded<T>(
    String path, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  Future<T> putFormUrlEncoded<T>(
    String path, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  Future<T> postFormData<T>(
    String path, {
    required FormData data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Converter<T>? converter,
  });

  // BaseResponse 전용 간편 메서드들
  Future<BaseResponse<T>> getBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Json? queryParameters,
    bool requiresAuthToken = true,
    String? contentType,
    Map<String, String>? headers,
  });

  Future<BaseResponse<T>> postBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
    Map<String, dynamic>? headers,
  });

  Future<BaseResponse<T>> putBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  });

  Future<BaseResponse<T>> patchBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  });

  Future<BaseResponse<T>> deleteBaseResponse<T>(
    String path, {
    required T Function(Json) fromJsonT,
    Json? queryParameters,
    bool requiresAuthToken = true,
  });
}
