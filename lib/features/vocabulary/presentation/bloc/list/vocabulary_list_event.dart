part of 'vocabulary_list_bloc.dart';

@freezed
class VocabularyListEvent with _$VocabularyListEvent {
  const factory VocabularyListEvent.initialized() = VocabularyInitialized;
  const factory VocabularyListEvent.loadItems() = VocabularyLoadItems;
  const factory VocabularyListEvent.searchChanged(String query) =
      VocabularySearchChanged;
  const factory VocabularyListEvent.refresh() = VocabularyRefresh;
  const factory VocabularyListEvent.unbookmark(VocabularyEntry item) =
      VocabularyUnbookmark;
  const factory VocabularyListEvent.unbookmarkSelected() =
      VocabularyUnbookmarkSelected;
  const factory VocabularyListEvent.toggleSelectionMode() =
      VocabularyToggleSelectionMode;
  const factory VocabularyListEvent.toggleItemSelection(String studyItemId) =
      VocabularyToggleItemSelection;
  const factory VocabularyListEvent.toggleAllSelection() =
      VocabularyToggleAllSelection;
  const factory VocabularyListEvent.loadFolders(
      {@Default(false) bool forceRefresh}) = VocabularyLoadFolders;
  const factory VocabularyListEvent.moveItemsToFolder(String? folderId) =
      VocabularyMoveItemsToFolder;
  const factory VocabularyListEvent.createFolder(String name) =
      VocabularyCreateFolder;
  const factory VocabularyListEvent.syncFolders(List<Folder> folders) =
      VocabularySyncFolders;

  // 상세 화면에서 폴더를 바꿨을 때, 목록 화면도 즉시 갱신되도록 찌르는 이벤트
  const factory VocabularyListEvent.updateItemFolderOptimistically(
          String studyItemId, String? folderId) =
      VocabularyUpdateItemFolderOptimistically;

  const factory VocabularyListEvent.sortTypeChanged(
      VocabularySortType sortType) = VocabularySortTypeChanged;
  const factory VocabularyListEvent.sortOrderChanged(
      VocabularySortOrder sortOrder) = VocabularySortOrderChanged;
  const factory VocabularyListEvent.resetOnLogout() = VocabularyResetOnLogout;
}
