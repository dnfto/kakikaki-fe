import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/network/base_repository.dart';
import 'package:kakikaki/features/diary/data/source/diary_remote_data_source.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';
import 'package:kakikaki/features/diary/domain/repository/diary_repository.dart';

@Injectable(as: DiaryRepository)
class DiaryRepositoryImpl extends BaseRepository implements DiaryRepository {
  DiaryRepositoryImpl(this._dataSource) : super('diary');

  final DiaryRemoteDataSource _dataSource;

  @override
  Future<Set<DateTime>> getWrittenDates({required String userId}) =>
      _dataSource.getWrittenDates(userId: userId);

  @override
  Future<DiaryListItem?> getDiaryByDate({
    required String userId,
    required DateTime date,
  }) =>
      _dataSource.getDiaryByDate(userId: userId, date: date);

  @override
  Future<void> deleteDiary({
    required String diaryId,
    required String userId,
  }) =>
      _dataSource.deleteDiary(diaryId: diaryId, userId: userId);

  @override
  Future<void> updateDiary({
    required String diaryId,
    required String newContent,
  }) =>
      _dataSource.updateDiary(diaryId: diaryId, newContent: newContent);
}
