part of 'vocabulary_detail_bloc.dart';

@freezed
class VocabularyDetailState with _$VocabularyDetailState {
  const factory VocabularyDetailState({
    @Default(true) bool isLoading,
    @Default('') String errorMessage,
    int? targetId, // 삭제 처리를 위해 현재 단어의 원본 ID 보관
    JLPTLevel? level,
    PartOfSpeech? pos,
    @Default('') String word,
    @Default('') String reading,
    String? ruby,
    @Default('') String meaningTranslated,
    @Default('') String exampleJp,
    @Default('') String exampleTranslated,
    @Default('') String exampleEn,
    String? diaryId,
    @Default('word') String type,
    @Default(true) bool isInitialLoad,
    @Default(false) bool hasBookmarkChanged,
    @Default([]) List<int> wordIds,
    @Default(0) int currentIndex,
    String? studyItemId,
    String? folderId,
    DiaryFeedbackResult? readyDiaryFeedback,

    // 버튼 로딩 및 교정 중 상태 분리
    @Default(false) bool isDiaryFetching,
    @Default(false) bool isDiaryProcessing,
    // 추천에서 제외되었음을 알리는 팝업 트리거
    @Default(false) bool showExcludedPopup,
  }) = _VocabularyDetailState;
}
