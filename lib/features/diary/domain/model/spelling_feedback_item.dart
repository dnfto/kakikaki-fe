import 'package:freezed_annotation/freezed_annotation.dart';

part 'spelling_feedback_item.freezed.dart';
part 'spelling_feedback_item.g.dart';

@freezed
class SpellingFeedbackItem with _$SpellingFeedbackItem {
  const factory SpellingFeedbackItem({
    required String original,
    required String corrected,
    required String reason,
  }) = _SpellingFeedbackItem;

  factory SpellingFeedbackItem.fromJson(Map<String, dynamic> json) =>
      _$SpellingFeedbackItemFromJson(json);
}
