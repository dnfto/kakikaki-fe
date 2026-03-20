import 'package:kakikaki/app/enums/auth_enums.dart';

/// 인증 관련 Repository 인터페이스
abstract class AuthRepository {
  /// 소셜 로그아웃 및 Supabase 세션 종료
  Future<void> logout(SocialType? socialType);
}
