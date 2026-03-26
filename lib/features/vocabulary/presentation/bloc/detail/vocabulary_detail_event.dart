part of 'vocabulary_detail_bloc.dart';

@freezed
class VocabularyDetailEvent with _$VocabularyDetailEvent {
  const factory VocabularyDetailEvent.detailLoaded(
    int targetId, {
    required VocabularyType type,
    @Default(true) bool showLoading,
  }) = VocabularyDetailLoaded;

  const factory VocabularyDetailEvent.diaryFeedbackRequested() =
      VocabularyDetailDiaryFeedbackRequested;
  const factory VocabularyDetailEvent.diaryFeedbackReset() =
      VocabularyDetailDiaryFeedbackReset;
  const factory VocabularyDetailEvent.bookmarkChanged() =
      VocabularyDetailBookmarkChanged;

  // UI에 있던 폴더 이동 로직을 BLoC이 처리하도록 이벤트 추가
  const factory VocabularyDetailEvent.moveToFolderRequested(String? folderId) =
      VocabularyDetailMoveToFolderRequested;

  // 단어장 삭제 요청 이벤트
  const factory VocabularyDetailEvent.unbookmarkRequested() =
      VocabularyDetailUnbookmarkRequested;

  // 웹소켓이 DB 변화를 감지했을 때 호출할 내부 이벤트
  const factory VocabularyDetailEvent.realtimeUpdated(
      Map<String, dynamic> diaryData) = VocabularyDetailRealtimeUpdated;

  // 팝업이 표시된 후 트리거를 리셋하는 이벤트
  const factory VocabularyDetailEvent.excludedPopupShown() =
      VocabularyDetailExcludedPopupShown;
}
