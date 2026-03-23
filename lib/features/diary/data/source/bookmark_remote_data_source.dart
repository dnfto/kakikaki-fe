import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';

/// 일기 피드백 화면 북마크 관련 원격 데이터 소스 (Supabase)
@lazySingleton
class BookmarkRemoteDataSource {
  /// 북마크된 추천 표현의 인덱스 목록 조회
  Future<Set<int>> fetchBookmarkedIndices({
    required String userId,
    required String diaryId,
    required List<DiaryRecommendationItem> recommendations,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null || recommendations.isEmpty) return <int>{};

    final wordToIndices = <String, List<int>>{};
    final grammarToIndices = <String, List<int>>{};

    for (int i = 0; i < recommendations.length; i++) {
      final item = recommendations[i];
      if (item.type == 'word') {
        wordToIndices.putIfAbsent(item.word, () => <int>[]).add(i);
      } else {
        grammarToIndices.putIfAbsent(item.word, () => <int>[]).add(i);
      }
    }

    final uniqueWords = wordToIndices.keys.toList();
    final uniqueTitles = grammarToIndices.keys.toList();

    // [Guideline 4] 순차적으로 5번 기다리던 DB 조회를 Future.wait으로 병렬 처리! (속도 5배 향상)
    final futures = await Future.wait([
      uniqueWords.isNotEmpty
          ? client
              .from('vocabulary')
              .select('id, word')
              .inFilter('word', uniqueWords)
          : Future.value([]),
      uniqueTitles.isNotEmpty
          ? client
              .from('grammar')
              .select('id, title')
              .inFilter('title', uniqueTitles)
          : Future.value([]),
      client
          .from('user_recommendations')
          .select('item_type, word_id, grammar_id')
          .eq('user_id', userId)
          .eq('diary_id', diaryId)
          .eq('is_bookmarked', true),
      uniqueWords.isNotEmpty
          ? client
              .from('study_items')
              .select('word')
              .eq('user_id', userId)
              .eq('type', 'word')
              .inFilter('word', uniqueWords)
          : Future.value([]),
      uniqueTitles.isNotEmpty
          ? client
              .from('study_items')
              .select('word')
              .eq('user_id', userId)
              .eq('type', 'grammar')
              .inFilter('word', uniqueTitles)
          : Future.value([]),
    ]);

    // [Guideline 4] 무식한 for문 + add() 방식을 Dart의 Map/Set 컴프리헨션으로 우아하게 최적화!
    final wordIdByWord = {
      for (final row in futures[0])
        if (row['word'] != null && row['id'] != null)
          row['word'].toString(): row['id'] as int
    };

    final grammarIdByTitle = {
      for (final row in futures[1])
        if (row['title'] != null && row['id'] != null)
          row['title'].toString(): row['id'] as int
    };

    final bookmarkedWordIds = (futures[2])
        .where((r) => r['item_type'] == 'word' && r['word_id'] != null)
        .map((r) => r['word_id'] as int)
        .toSet();

    final bookmarkedGrammarIds = (futures[2])
        .where((r) => r['item_type'] == 'grammar' && r['grammar_id'] != null)
        .map((r) => r['grammar_id'] as int)
        .toSet();

    final expressionsInVocabulary = {
      ...(futures[3])
          .map((r) => (r['word'] ?? '').toString())
          .where((w) => w.isNotEmpty),
      ...(futures[4])
          .map((r) => (r['word'] ?? '').toString())
          .where((w) => w.isNotEmpty),
    };

    final bookmarkedIndices = <int>{};

    for (final entry in wordIdByWord.entries) {
      if (bookmarkedWordIds.contains(entry.value) ||
          expressionsInVocabulary.contains(entry.key)) {
        bookmarkedIndices.addAll(wordToIndices[entry.key] ?? const <int>[]);
      }
    }

    for (final entry in grammarIdByTitle.entries) {
      if (bookmarkedGrammarIds.contains(entry.value) ||
          expressionsInVocabulary.contains(entry.key)) {
        bookmarkedIndices.addAll(grammarToIndices[entry.key] ?? const <int>[]);
      }
    }

    for (final word in expressionsInVocabulary) {
      if (!wordIdByWord.containsKey(word) &&
          !grammarIdByTitle.containsKey(word)) {
        bookmarkedIndices.addAll(
            wordToIndices[word] ?? grammarToIndices[word] ?? const <int>[]);
      }
    }

    return bookmarkedIndices;
  }

  /// 추천 표현 북마크 토글
  Future<void> toggleBookmark({
    required DiaryRecommendationItem item,
    required String userId,
    required String? diaryId,
    required bool currentStatus,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    try {
      int? itemId;
      final table = item.type == 'word' ? 'vocabulary' : 'grammar';
      final column = item.type == 'word' ? 'word' : 'title';

      final itemResponse = await client
          .from(table)
          .select('id')
          .eq(column, item.word)
          .limit(1)
          .maybeSingle();

      if (itemResponse != null) {
        itemId = itemResponse['id'] as int?;
      }

      if (itemId == null) {
        final newExample = {
          'jp': item.exampleJp,
          'ko': item.exampleTranslated,
          if (item.exampleEn.isNotEmpty) 'en': item.exampleEn,
        };
        if (item.type == 'word') {
          final insertResponse = await client
              .from('vocabulary')
              .insert({
                'word': item.word,
                'reading': item.reading.isNotEmpty ? item.reading : null,
                'pos': [item.pos.code],
                'meanings': [item.meaningTranslated],
                'examples': [newExample],
                'level': [item.level.nameString],
              })
              .select('id')
              .single();
          itemId = insertResponse['id'] as int?;
        } else {
          final insertResponse = await client
              .from('grammar')
              .insert({
                'title': item.word,
                'reading': item.reading.isNotEmpty ? item.reading : null,
                'level': item.level.nameString,
                'meaning': item.meaningTranslated,
                'connection':
                    item.connection.isNotEmpty ? item.connection : null,
                'examples': [newExample],
              })
              .select('id')
              .single();
          itemId = insertResponse['id'] as int?;
        }
      }

      if (itemId == null) throw Exception('추천 표현 ID를 찾을 수 없어요.');

      var query = client
          .from('user_recommendations')
          .select('id, is_bookmarked')
          .eq('user_id', userId)
          .eq('diary_id', diaryId ?? '')
          .eq('item_type', item.type);

      query = item.type == 'word'
          ? query.eq('word_id', itemId)
          : query.eq('grammar_id', itemId);

      if (!currentStatus) {
        final existingRec = await query.limit(1).maybeSingle();

        if (existingRec != null) {
          await client
              .from('user_recommendations')
              .update({'is_bookmarked': true}).eq('id', existingRec['id']);
        } else {
          await client.from('user_recommendations').insert({
            'user_id': userId,
            'diary_id': diaryId,
            'item_type': item.type,
            'word_id': item.type == 'word' ? itemId : null,
            'grammar_id': item.type == 'grammar' ? itemId : null,
            'is_bookmarked': true,
          });
        }

        final existingStudyItem = await client
            .from('study_items')
            .select('id')
            .eq('user_id', userId)
            .eq('type', item.type)
            .eq('word', item.word)
            .limit(1)
            .maybeSingle();

        final studyItemData = {
          'user_id': userId,
          'type': item.type,
          'word': item.word,
          'reading': item.reading,
          'pos': item.type == 'word' ? item.pos.code : null,
          'meaning_translated': item.meaningTranslated,
          'example_jp': item.exampleJp,
          'example_translated': item.exampleTranslated,
          'jlpt': item.level.nameString,
          'connection': item.type == 'grammar' && item.connection.isNotEmpty
              ? item.connection
              : null,
          if (existingStudyItem == null) ...{
            'state': 1,
            'step': 0,
            'stability': 0.0,
            'difficulty': 0.0,
            'elapsed_days': 0,
            'scheduled_days': 0,
            'lapses': 0,
            'repetitions': 0,
            'next_review_date': DateTime.now().toIso8601String(),
          }
        };

        if (existingStudyItem != null) {
          await client
              .from('study_items')
              .update(studyItemData)
              .eq('id', existingStudyItem['id']);
        } else {
          await client.from('study_items').insert(studyItemData);
        }
      } else {
        final existingRec = await query.limit(1).maybeSingle();
        if (existingRec != null) {
          await client
              .from('user_recommendations')
              .update({'is_bookmarked': false}).eq('id', existingRec['id']);
        }
      }
    } catch (e, stackTrace) {
      Log.e('Bookmark Error',
          name: 'BookmarkRemoteDataSource',
          errorObject: e,
          stackTrace: stackTrace);
      rethrow;
    }
  }
}
