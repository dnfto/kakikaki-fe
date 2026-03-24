import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/study/data/source/study_remote_data_source.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';
import 'package:kakikaki/features/study/domain/repository/study_repository.dart';

@Injectable(as: StudyRepository)
class StudyRepositoryImpl implements StudyRepository {
  StudyRepositoryImpl(this._dataSource);

  final StudyRemoteDataSource _dataSource;

  @override
  Future<List<StudyEntry>> loadStudyItems({
    required String userId,
    String? folderId,
  }) =>
      _dataSource.loadStudyItems(userId: userId, folderId: folderId);

  @override
  Future<List<Folder>> loadFolders({required String userId}) =>
      _dataSource.loadFolders(userId: userId);

  @override
  Future<Folder> createFolder({
    required String userId,
    required String name,
  }) =>
      _dataSource.createFolder(userId: userId, name: name);

  @override
  Future<void> updateFolderName({
    required String folderId,
    required String name,
  }) =>
      _dataSource.updateFolderName(folderId: folderId, name: name);

  @override
  Future<void> deleteFolder({
    required String folderId,
    required String userId,
  }) =>
      _dataSource.deleteFolder(folderId: folderId, userId: userId);

  @override
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
  }) =>
      _dataSource.updateReviewState(
        itemId: itemId,
        state: state,
        step: step,
        stability: stability,
        difficulty: difficulty,
        elapsedDays: elapsedDays,
        scheduledDays: scheduledDays,
        lapses: lapses,
        repetitions: repetitions,
        nextReviewDate: nextReviewDate,
        lastReviewDate: lastReviewDate,
      );

  @override
  Future<void> updateCardContent({
    required String itemId,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
  }) =>
      _dataSource.updateCardContent(
        itemId: itemId,
        meaningTranslated: meaningTranslated,
        exampleJp: exampleJp,
        exampleTranslated: exampleTranslated,
      );

  @override
  Future<void> updateStudyItemFolder({
    required String itemId,
    String? folderId,
  }) =>
      _dataSource.updateStudyItemFolder(itemId: itemId, folderId: folderId);

  @override
  Future<List<Map<String, dynamic>>> fetchAllExamples({
    required String word,
    required String type,
  }) =>
      _dataSource.fetchAllExamples(word: word, type: type);
}
