// 문의 종류
enum InquiryCategory {
  bug(label: '오류 제보', code: 'bug'),
  featureRequest(label: '기능 제안', code: 'feature_request'),
  etc(label: '기타', code: 'etc');

  final String label;
  final String code;

  const InquiryCategory({required this.label, required this.code});
}
