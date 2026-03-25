part of 'diary_feedback_bloc.dart';

@freezed
class DiaryFeedbackState with _$DiaryFeedbackState {
  const factory DiaryFeedbackState({
    // [Guideline 8] UI 전용 휘발성 상태(showFurigana, showCorrected, shouldGoHome) 삭제!
    @Default(<int>{}) Set<int> bookmarkedIndices,
    @Default(false) bool hasBookmarkChanged,
    @Default(false) bool isDeleted,
    @Default(false) bool isPremiumLimitReached,
  }) = _DiaryFeedbackState;
}
