import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/usecase/build_diary_feedback_result_usecase.dart';

enum FeedbackProcessStatus { processing, completed, failed }

class FeedbackProcessResponse {
  final FeedbackProcessStatus status;
  final DiaryFeedbackResult? result;

  FeedbackProcessResponse({required this.status, this.result});
}

@injectable
class GetDiaryFeedbackUseCase {
  final BuildDiaryFeedbackResultUseCase _buildResultUseCase;

  GetDiaryFeedbackUseCase(this._buildResultUseCase);

  /// JSON 형태의 DB 데이터를 받아 공통된 규칙으로 결과를 검사하고 조립합니다.
  Future<FeedbackProcessResponse> call(Map<String, dynamic> diaryData) async {
    final statusStr = diaryData['feedback_status']?.toString() ?? '';

    // 1. 처리 중일 때는 거부!
    if (statusStr == 'pending' || statusStr == 'processing') {
      return FeedbackProcessResponse(status: FeedbackProcessStatus.processing);
    }

    // 2. 완료 또는 실패일 때는 조립 시작
    final diaryId = diaryData['id']?.toString() ?? '';
    final createdAtStr = diaryData['created_at']?.toString() ?? '';
    final createdAt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

    final result = await _buildResultUseCase.call(
      diaryId: diaryId,
      createdAt: createdAt,
      content: (diaryData['content'] ?? '').toString(),
      // 교정본이 비어있으면(실패 등) 안전하게 원문을 꽂아주기
      correctedContent:
          (diaryData['corrected_content'] ?? diaryData['content'] ?? '')
              .toString(),
      contentFurigana: (diaryData['content_furigana'] ?? '').toString(),
      correctedContentFurigana:
          (diaryData['corrected_content_furigana'] ?? '').toString(),
      correctionNotes: diaryData['correction_notes'],
    );

    return FeedbackProcessResponse(
      status: statusStr == 'failed'
          ? FeedbackProcessStatus.failed
          : FeedbackProcessStatus.completed,
      result: result,
    );
  }
}
