import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/mixin/log_mixin.dart';
import 'package:kakikaki/core/network/api_service.dart';

abstract class BaseRepository with LogMixin {
  const BaseRepository(this.path);
  final String path;
  Future<ApiService> get apiService => getIt.getAsync<ApiService>();

  void _logDuration(Duration duration) {
    String two(int n) => n.toString().padLeft(2, '0');
    final msg = '소요 시간: '
        '${two(duration.inHours)} h '
        '${two(duration.inMinutes.remainder(60))} m '
        '${two(duration.inSeconds.remainder(60))} s';

    logI(msg);
  }

  /// API 호출 → 모델 변환
  Future<T> fetchData<T>({
    required String endpoint,
    Converter<T>? converter,
    Map<String, String>? customHeaders,
    String? contentType,
    void Function()? onStart,
    void Function()? onEnd,
    bool requiresAuthToken = true,
    Json? queryParameters,
  }) async {
    Stopwatch stopwatch = Stopwatch()..start();
    onStart?.call();
    final service = await apiService;
    final response = await service.getJson(endpoint,
        headers: customHeaders,
        contentType: contentType,
        requiresAuthToken: requiresAuthToken,
        queryParameters: queryParameters,
        converter: converter);
    onEnd?.call();
    stopwatch.stop();
    _logDuration(stopwatch.elapsed);
    return response;
  }

  // BaseResponse 전용 간편 메서드들
  Future<BaseResponse<T>> getBase<T>(
    String endpoint,
    T Function(Json) fromJsonT, {
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) async {
    final service = await apiService;
    return service.getBaseResponse(
      endpoint,
      fromJsonT: fromJsonT,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
    );
  }

  Future<BaseResponse<T>> postBase<T>(
    String endpoint,
    T Function(Json) fromJsonT, {
    required Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) async {
    final service = await apiService;
    return service.postBaseResponse(
      endpoint,
      fromJsonT: fromJsonT,
      data: data,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
    );
  }

  Future<BaseResponse<T>> putBase<T>(
    String endpoint,
    T Function(Json) fromJsonT, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) async {
    final service = await apiService;
    return service.putBaseResponse(
      endpoint,
      fromJsonT: fromJsonT,
      data: data,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
    );
  }

  Future<BaseResponse<T>> patchBase<T>(
    String endpoint,
    T Function(Json) fromJsonT, {
    Object? data,
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) async {
    final service = await apiService;
    return service.patchBaseResponse(
      endpoint,
      fromJsonT: fromJsonT,
      data: data,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
    );
  }

  Future<BaseResponse<T>> deleteBase<T>(
    String endpoint,
    T Function(Json) fromJsonT, {
    Json? queryParameters,
    bool requiresAuthToken = true,
  }) async {
    final service = await apiService;
    return service.deleteBaseResponse(
      endpoint,
      fromJsonT: fromJsonT,
      queryParameters: queryParameters,
      requiresAuthToken: requiresAuthToken,
    );
  }
}
