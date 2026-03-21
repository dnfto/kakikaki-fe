/// 문의사항 관련 Repository 인터페이스
abstract class InquiryRepository {
  /// 문의사항 전송
  Future<void> submitInquiry({
    required String userId,
    required String category,
    required String title,
    required String content,
  });

  /// 사용자의 문의 내역 조회
  Future<List<Map<String, dynamic>>> getInquiries({
    required String userId,
  });
}
