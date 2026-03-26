import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

part 'study_state.freezed.dart';

@freezed
class StudyState with _$StudyState {
  const factory StudyState({
    @Default([]) List<StudyEntry> items,
    @Default(0) int currentIndex,
    String? selectedFolderId,
    @Default([]) List<Folder> folders,
    @Default(false) bool isFolderSelected,

    // [Guideline 8] 순수 UI 애니메이션 상태(isCardFlipped) 삭제

    // [Guideline 6] 예문 로딩 상태 및 결과 BLoC으로 이관
    @Default(false) bool isLoadingExamples,
    @Default([]) List<Map<String, dynamic>> currentExamples,
    DateTime? foldersCacheTime,
    DateTime? premiumStatusCacheTime,
  }) = _StudyState;
}
