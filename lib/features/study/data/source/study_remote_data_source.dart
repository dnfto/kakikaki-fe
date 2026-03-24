import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

/// 학습 데이터 Supabase 통신 DataSource
@lazySingleton
class StudyRemoteDataSource {
  Future<List<StudyEntry>> loadStudyItems({
    required String userId,
    String? folderId,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) throw Exception('서버 초기화가 되지 않았어요.');

    final nowStr = DateTime.now().toIso8601String();

    var query = client
        .from('study_items')
        .select(
            'id, type, word, reading, pos, meaning_translated, example_jp, example_translated, jlpt, connection, next_review_date, folder_id, state, step, stability, difficulty, elapsed_days, scheduled_days, lapses, repetitions, last_review_date')
        .eq('user_id', userId)
        .lte('next_review_date', nowStr);

    if (folderId == '__uncategorized__') {
      query = query.isFilter('folder_id', null);
    } else if (folderId != null) {
      query = query.eq('folder_id', folderId);
    }

    final response = await query.order('next_review_date', ascending: true);

    return (response as List)
        .map((json) => StudyEntry.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<Folder>> loadFolders({required String userId}) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    final response = await client
        .from('folders')
        .select('id, name, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => Folder.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Folder> createFolder({
    required String userId,
    required String name,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    final response = await client
        .from('folders')
        .insert({'user_id': userId, 'name': name})
        .select()
        .single();

    return Folder.fromJson(response);
  }

  Future<void> updateFolderName({
    required String folderId,
    required String name,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    await client.from('folders').update({'name': name}).eq('id', folderId);
  }

  Future<void> deleteFolder({
    required String folderId,
    required String userId,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    await client
        .from('study_items')
        .update({'folder_id': null})
        .eq('folder_id', folderId)
        .eq('user_id', userId);

    await client.from('folders').delete().eq('id', folderId);
  }

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
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    final payload = <String, dynamic>{
      'state': state,
      'stability': stability,
      'difficulty': difficulty,
      'elapsed_days': elapsedDays,
      'scheduled_days': scheduledDays,
      'lapses': lapses,
      'repetitions': repetitions,
      'next_review_date': nextReviewDate.toIso8601String(),
    };
    if (step != null) payload['step'] = step;
    if (lastReviewDate != null) {
      payload['last_review_date'] = lastReviewDate.toIso8601String();
    }

    await client.from('study_items').update(payload).eq('id', itemId);
  }

  Future<void> updateCardContent({
    required String itemId,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }
    await client.from('study_items').update({
      'meaning_translated': meaningTranslated,
      'example_jp': exampleJp,
      'example_translated': exampleTranslated,
    }).eq('id', itemId);
  }

  Future<void> updateStudyItemFolder({
    required String itemId,
    String? folderId,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요.');
    }

    await client
        .from('study_items')
        .update({'folder_id': folderId}).eq('id', itemId);
  }

  Future<List<Map<String, dynamic>>> fetchAllExamples({
    required String word,
    required String type,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return [];

    final table = type == 'word' ? 'vocabulary' : 'grammar';
    final column = type == 'word' ? 'word' : 'title';

    try {
      final response = await client
          .from(table)
          .select('examples')
          .eq(column, word)
          .limit(1)
          .maybeSingle();

      if (response != null && response['examples'] != null) {
        final examples = response['examples'];
        if (examples is List) {
          return examples
              .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
