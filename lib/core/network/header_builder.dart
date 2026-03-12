/// HTTP 요청 헤더를 빌드하는 인터페이스
///
/// 클린 아키텍처 원칙에 따라 ApiService가 구체적인 구현에 의존하지 않고
/// 인터페이스에만 의존하도록 합니다.
abstract class HeaderBuilder {
  /// 기본 헤더를 빌드합니다.
  ///
  /// [requiresAuthToken]: 인증 토큰이 필요한지 여부
  /// [customHeaders]: 추가 커스텀 헤더
  ///
  /// Returns: 빌드된 헤더 맵
  Map<String, dynamic> buildHeaders({
    required bool requiresAuthToken,
    Map<String, dynamic>? customHeaders,
  });
}

