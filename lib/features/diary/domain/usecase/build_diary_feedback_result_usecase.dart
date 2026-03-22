import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/model/spelling_feedback_item.dart';
import 'package:kakikaki/features/diary/domain/repository/diary_recommendation_repository.dart';

/// 일기 피드백 결과를 조립하는 Use Case
@injectable
class BuildDiaryFeedbackResultUseCase {
  final DiaryRecommendationRepository _recommendationRepository;

  BuildDiaryFeedbackResultUseCase(this._recommendationRepository);

  Future<DiaryFeedbackResult> call({
    required String diaryId,
    required DateTime createdAt,
    required String content,
    required String correctedContent,
    required String contentFurigana,
    required String correctedContentFurigana,
    required dynamic correctionNotes,
  }) async {
    final recommendations =
        await _recommendationRepository.fetchRecommendationsByDiaryId(
      diaryId: diaryId,
    );

    // [Guideline 4 & 3 적용] 무식한 for문 파싱 대신, List map과 fromJson 팩토리를 이용해 깔끔하게 맵핑
    final spellings = (correctionNotes is List)
        ? correctionNotes
            .whereType<Map<String, dynamic>>()
            .map((note) => SpellingFeedbackItem.fromJson({
                  'original': note['original']?.toString() ?? '',
                  'corrected': note['corrected']?.toString() ?? '',
                  'reason': note['reason']?.toString() ?? '',
                }))
            .toList()
        : <SpellingFeedbackItem>[];

    return DiaryFeedbackResult(
      diaryId: diaryId,
      date: createdAt,
      originalText: content,
      correctedText: correctedContent,
      contentFurigana: contentFurigana,
      correctedContentFurigana: correctedContentFurigana,
      spellingFeedback: spellings,
      recommendations: recommendations,
    );
  }
}
