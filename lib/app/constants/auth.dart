class AuthConstants {
  // Storage Keys
  static const String accessTokenKey = 'AuthProvider.token';
  static const String refreshTokenKey = 'AuthProvider.reToken';
  static const String userKey = 'AuthProvider.user';
  // 마지막으로 Supabase에 동기화 성공한 FCM 토큰(중복 DB 쓰기 방지용)
  static const String fcmTokenKey = 'AuthProvider.fcmToken';
  static const String redirectUrlKey = 'redirect_url'; // 딥링크 리다이렉트 URL 저장 키

  // API Path Patterns (401 시 로그아웃 방지용)
  /// 토큰 관련 API 경로 패턴 (로그인 시도 시 자동 로그아웃 방지)
  static const String tokenApiPathPattern = '/users/token';

  // Route Patterns
  /// 회원가입 라우트 패턴 (회원가입 중 자동 로그아웃 방지)
  static const String signUpRoutePattern = '/auth/sign-up';
}
