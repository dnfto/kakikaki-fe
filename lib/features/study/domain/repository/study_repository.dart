import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

/// 학습 데이터 Repository 인터페이스
abstract class StudyRepository {
  Future<List<StudyEntry>> loadStudyItems({
    required String userId,
    String? folderId,
  });

  Future<List<Folder>> loadFolders({required String userId});

  Future<Folder> createFolder({
    required String userId,
    required String name,
  });

  Future<void> updateFolderName({
    required String folderId,
    required String name,
  });

  Future<void> deleteFolder({
    required String folderId,
    required String userId,
  });

  Future<void> updateReviewState({
    required String itemId,
    required int state,
    int? step,
    required double stability,
    required double difficulty,
    required int elapsedDays,
    required int scheduledDays,
    required int lapses,
    required int repetitions,
    required DateTime nextReviewDate,
    DateTime? lastReviewDate,
  });

  Future<void> updateCardContent({
    required String itemId,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
  });

  Future<void> updateStudyItemFolder({
    required String itemId,
    String? folderId,
  });

  Future<List<Map<String, dynamic>>> fetchAllExamples({
    required String word,
    required String type,
  });
}
