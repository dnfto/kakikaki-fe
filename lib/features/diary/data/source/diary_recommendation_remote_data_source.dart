import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

/// 일기 추천 단어/문법 원격 데이터 소스 (Supabase)
@lazySingleton
class DiaryRecommendationRemoteDataSource {
  /// user_recommendations + vocabulary/grammar 병렬 조회 후 원시 데이터 반환
  Future<DiaryRecommendationRawData> fetchRecommendations(
      String diaryId) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    final userRecResponse = await client
        .from('user_recommendations')
        .select('word_id, grammar_id')
        .eq('diary_id', diaryId)
        .order('created_at', ascending: false);

    final rows = (userRecResponse as List).cast<Map<String, dynamic>>();

    final seenWordIds = <int>{};
    final seenGrammarIds = <int>{};
    final uniqueRows = <Map<String, dynamic>>[];

    for (final row in rows) {
      final wordId = row['word_id'] as int?;
      final grammarId = row['grammar_id'] as int?;

      if (wordId != null && !seenWordIds.contains(wordId)) {
        seenWordIds.add(wordId);
        uniqueRows.add(row);
      } else if (grammarId != null && !seenGrammarIds.contains(grammarId)) {
        seenGrammarIds.add(grammarId);
        uniqueRows.add(row);
      }
    }

    final wordIds = seenWordIds.toList();
    final grammarIds = seenGrammarIds.toList();

    final vocabularyById = <int, Map<String, dynamic>>{};
    final grammarById = <int, Map<String, dynamic>>{};

    await Future.wait([
      if (wordIds.isNotEmpty)
        client
            .from('vocabulary')
            .select('id, word, reading, ruby, pos, meanings, examples, level')
            .inFilter('id', wordIds)
            .then((response) {
          for (final item in (response as List).cast<Map<String, dynamic>>()) {
            final id = item['id'] as int?;
            if (id != null) vocabularyById[id] = item;
          }
        }),
      if (grammarIds.isNotEmpty)
        client
            .from('grammar')
            .select('id, title, reading, ruby, level, meaning, examples')
            .inFilter('id', grammarIds)
            .then((response) {
          for (final item in (response as List).cast<Map<String, dynamic>>()) {
            final id = item['id'] as int?;
            if (id != null) grammarById[id] = item;
          }
        }),
    ]);

    return DiaryRecommendationRawData(
      uniqueRows: uniqueRows,
      vocabularyById: vocabularyById,
      grammarById: grammarById,
    );
  }
}

/// DataSource가 반환하는 원시 데이터 (Repository에서 Entity로 변환용)
class DiaryRecommendationRawData {
  DiaryRecommendationRawData({
    required this.uniqueRows,
    required this.vocabularyById,
    required this.grammarById,
  });

  final List<Map<String, dynamic>> uniqueRows;
  final Map<int, Map<String, dynamic>> vocabularyById;
  final Map<int, Map<String, dynamic>> grammarById;
}
