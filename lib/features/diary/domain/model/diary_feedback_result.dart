import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/features/diary/domain/model/spelling_feedback_item.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';

part 'diary_feedback_result.freezed.dart';
part 'diary_feedback_result.g.dart';

@freezed
class DiaryFeedbackResult with _$DiaryFeedbackResult {
  const factory DiaryFeedbackResult({
    required String diaryId,
    required DateTime date,
    required String originalText,
    required String correctedText,
    @Default('') String contentFurigana,
    @Default('') String correctedContentFurigana,
    required List<SpellingFeedbackItem> spellingFeedback,
    required List<DiaryRecommendationItem> recommendations,
  }) = _DiaryFeedbackResult;

  factory DiaryFeedbackResult.fromJson(Map<String, dynamic> json) =>
      _$DiaryFeedbackResultFromJson(json);
}
