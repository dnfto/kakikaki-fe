import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/core/domain/model/review_level.dart';
import 'package:kakikaki/features/study/domain/model/review_result.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

part 'study_event.freezed.dart';

@freezed
class StudyEvent with _$StudyEvent {
  const factory StudyEvent.initialized() = StudyInitialized;
  const factory StudyEvent.checkPremiumStatus() = StudyCheckPremiumStatus;
  const factory StudyEvent.refresh() = StudyRefresh;
  const factory StudyEvent.resetOnLogout() = StudyResetOnLogout;

  const factory StudyEvent.loadFolders() = StudyLoadFolders;
  const factory StudyEvent.selectFolder({String? folderId}) = StudySelectFolder;
  const factory StudyEvent.goToFolderSelection() = StudyGoToFolderSelection;
  const factory StudyEvent.createFolder(String name) = StudyCreateFolder;
  const factory StudyEvent.updateFolderName({
    required String folderId,
    required String name,
  }) = StudyUpdateFolderName;
  const factory StudyEvent.deleteFolder(String folderId) = StudyDeleteFolder;

  const factory StudyEvent.loadItems({String? folderId}) = StudyLoadItems;

  // [Guideline 8] 순수 UI 애니메이션인 flipCard 제거!

  // [Guideline 6] UI에서 호출하던 예문 로드 비즈니스 로직 이관!
  const factory StudyEvent.loadExamples({
    required String word,
    required String type,
  }) = StudyLoadExamples;

  const factory StudyEvent.reviewCompleted({
    required StudyEntry entry,
    required ReviewLevel level,
    required ReviewResult result,
  }) = StudyReviewCompleted;

  const factory StudyEvent.moveCardToFolder({
    required StudyEntry entry,
    String? folderId,
  }) = StudyMoveCardToFolder;

  const factory StudyEvent.updateCardContent({
    required String entryId,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
  }) = StudyUpdateCardContent;
}
