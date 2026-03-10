import 'package:freezed_annotation/freezed_annotation.dart';

part 'base_response.freezed.dart';
part 'base_response.g.dart';

@Freezed(genericArgumentFactories: true)
class BaseResponse<T> with _$BaseResponse<T> {
  const factory BaseResponse({
    required bool success,
    required Map<String, dynamic> meta,
    required T data,
    ErrorResponse? error,
  }) = _BaseResponse<T>;

  // Freezed가 자동 생성한 fromJson 사용 (_$$BaseResponseImplFromJson)
  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) =>
      _$$BaseResponseImplFromJson(json, fromJsonT);
}

/// BaseResponse 파싱 범용 헬퍼 함수
///
/// 사용법:
/// ```dart
/// converter: parseBaseResponse(SpotReviewListData.fromJson),
/// ```
BaseResponse<T> Function(dynamic) parseBaseResponse<T>(
  T Function(Map<String, dynamic>) fromJson,
) {
  return (json) => BaseResponse.fromJson(
        json as Map<String, dynamic>,
        (data) => fromJson(data as Map<String, dynamic>),
      );
}

@freezed
class ErrorResponse with _$ErrorResponse {
  const factory ErrorResponse({
    required int statusCode,
    required String code,
    required dynamic message,
  }) = _ErrorResponse;

  // Freezed가 자동 생성한 fromJson 사용
  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$$ErrorResponseImplFromJson(json);
}
