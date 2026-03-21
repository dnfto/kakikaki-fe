/// 사용자 정보 관련 Repository 인터페이스
abstract class UserRepository {
  /// 닉네임 업데이트
  Future<void> updateNickname({
    required String userId,
    required String newNickname,
  });

  /// 회원 탈퇴 (Edge Function 호출)
  Future<void> deleteAccount({String? reason});

  /// 프리미엄(구독) 상태 확인
  Future<bool> checkPremiumStatus({required String userId});
}
