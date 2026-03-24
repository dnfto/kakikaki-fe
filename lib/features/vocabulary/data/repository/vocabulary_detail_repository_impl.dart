import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/vocabulary/data/source/vocabulary_detail_remote_data_source.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_detail_info.dart';
import 'package:kakikaki/features/vocabulary/domain/repository/vocabulary_detail_repository.dart';

@Injectable(as: VocabularyDetailRepository)
class VocabularyDetailRepositoryImpl implements VocabularyDetailRepository {
  VocabularyDetailRepositoryImpl(this._dataSource);

  final VocabularyDetailRemoteDataSource _dataSource;

  final Map<String, VocabularyDetailInfo?> _detailCache = {};
  final Map<String, Map<String, dynamic>?> _diaryCache = {};

  String _detailCacheKey(int id, VocabularyType type) => '${type.name}_$id';

  @override
  Future<VocabularyDetailInfo?> fetchDetailById(
    int id, {
    String? userId,
    VocabularyType type = VocabularyType.word,
    bool forceRefresh = false,
  }) async {
    final cacheKey = _detailCacheKey(id, type);
    if (!forceRefresh && _detailCache.containsKey(cacheKey)) {
      return _detailCache[cacheKey];
    }

    final result =
        await _dataSource.fetchDetailById(id, userId: userId, type: type);
    _detailCache[cacheKey] = result;
    return result;
  }

  @override
  Future<Map<String, dynamic>?> fetchDiaryById(
    String diaryId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _diaryCache.containsKey(diaryId)) {
      return _diaryCache[diaryId];
    }

    final result = await _dataSource.fetchDiaryById(diaryId);
    _diaryCache[diaryId] = result;
    return result;
  }
}
