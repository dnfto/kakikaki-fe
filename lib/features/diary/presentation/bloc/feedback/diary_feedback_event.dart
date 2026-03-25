part of 'diary_feedback_bloc.dart';

@freezed
class DiaryFeedbackEvent with _$DiaryFeedbackEvent {
  const factory DiaryFeedbackEvent.loadBookmarksRequested({
    required String diaryId,
    required List<DiaryRecommendationItem> recommendations,
    @Default(false) bool forceRefresh,
  }) = DiaryFeedbackLoadBookmarksRequested;

  const factory DiaryFeedbackEvent.bookmarkToggled({
    required int index,
    required DiaryRecommendationItem item,
    required String diaryId,
  }) = DiaryFeedbackBookmarkToggled;

  const factory DiaryFeedbackEvent.deleteRequested({
    required String diaryId,
    required DateTime date,
  }) = DiaryFeedbackDeleteRequested;
  const factory DiaryFeedbackEvent.premiumPopupShown() =
      DiaryFeedbackPremiumPopupShown;
}
