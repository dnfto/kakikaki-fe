import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/network/base_repository.dart';
import 'package:kakikaki/features/diary/data/source/bookmark_remote_data_source.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';
import 'package:kakikaki/features/diary/domain/repository/bookmark_repository.dart';

@Injectable(as: BookmarkRepository)
class BookmarkRepositoryImpl extends BaseRepository
    implements BookmarkRepository {
  BookmarkRepositoryImpl(this._dataSource) : super('diary/bookmarks');

  final BookmarkRemoteDataSource _dataSource;

  @override
  Future<Set<int>> fetchBookmarkedIndices({
    required String userId,
    required String diaryId,
    required List<DiaryRecommendationItem> recommendations,
  }) =>
      _dataSource.fetchBookmarkedIndices(
        userId: userId,
        diaryId: diaryId,
        recommendations: recommendations,
      );

  @override
  Future<void> toggleBookmark({
    required DiaryRecommendationItem item,
    required String userId,
    required String diaryId,
    required bool currentStatus,
  }) =>
      _dataSource.toggleBookmark(
        item: item,
        userId: userId,
        diaryId: diaryId,
        currentStatus: currentStatus,
      );
}
