part of 'vocabulary_list_bloc.dart';

/// 정렬 타입
enum VocabularySortType {
  word, // 단어순
  date, // 날짜순 (최신순)
  level, // 레벨순
  type, // 타입순 (어휘/문형)
}

/// 정렬 순서
enum VocabularySortOrder {
  ascending, // 오름차순
  descending, // 내림차순
}

@freezed
class VocabularyListState with _$VocabularyListState {
  const factory VocabularyListState({
    String? errorMessage,
    @Default([]) List<VocabularyEntry> allItems,
    @Default([]) List<VocabularyEntry> filteredItems,
    @Default('') String searchQuery,
    @Default(false) bool isSelectionMode,
    @Default({}) Set<String> selectedItemIds,
    @Default([]) List<Folder> folders,
    @Default(VocabularySortType.word) VocabularySortType sortType,
    @Default(VocabularySortOrder.ascending) VocabularySortOrder sortOrder,
  }) = _VocabularyListState;
}
