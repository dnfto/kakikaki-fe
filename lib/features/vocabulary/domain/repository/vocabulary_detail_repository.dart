import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_detail_info.dart';

/// 단어/문법 상세 정보 Repository 인터페이스
abstract class VocabularyDetailRepository {
  Future<VocabularyDetailInfo?> fetchDetailById(
    int id, {
    String? userId,
    VocabularyType type = VocabularyType.word,
    bool forceRefresh = false,
  });

  Future<Map<String, dynamic>?> fetchDiaryById(
    String diaryId, {
    bool forceRefresh = false,
  });
}
