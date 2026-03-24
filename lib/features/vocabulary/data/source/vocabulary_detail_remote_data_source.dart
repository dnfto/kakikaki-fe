import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_detail_info.dart';

/// 단어/문법 상세 Supabase 통신 DataSource
@lazySingleton
class VocabularyDetailRemoteDataSource {
  Future<VocabularyDetailInfo?> fetchDetailById(int id,
      {String? userId, VocabularyType type = VocabularyType.word}) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return null;

    if (type == VocabularyType.grammar) {
      return _fetchGrammarDetail(client, id, userId);
    }
    return _fetchVocabularyDetail(client, id, userId);
  }

  Future<VocabularyDetailInfo?> _fetchVocabularyDetail(
      dynamic client, int id, String? userId) async {
    var response = await client
        .from('vocabulary')
        .select('id, word, reading, ruby, pos, meanings, examples, level')
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final json = response as Map<String, dynamic>;
    String? diaryId;
    String? studyItemId;
    String? folderId;
    final word = (json['word'] ?? '').toString();

    final userRecResponse = await client
        .from('user_recommendations')
        .select('diary_id')
        .eq('word_id', id)
        .limit(1)
        .maybeSingle();
    diaryId = userRecResponse?['diary_id']?.toString();

    if (userId != null) {
      final studyItemResponse = await client
          .from('study_items')
          .select('id, folder_id')
          .eq('user_id', userId)
          .eq('type', 'word')
          .eq('word', word)
          .limit(1)
          .maybeSingle();
      studyItemId = studyItemResponse?['id']?.toString();
      folderId = studyItemResponse?['folder_id']?.toString();
    }

    final posList =
        (json['pos'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final examples = (json['examples'] as List?) ?? [];
    Map<String, dynamic> firstExample = {};
    if (examples.isNotEmpty && examples.first is Map<String, dynamic>) {
      firstExample = examples.first as Map<String, dynamic>;
    }
    final levelList =
        (json['level'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return VocabularyDetailInfo(
      word: word,
      reading: (json['reading'] ?? '').toString(),
      ruby: (json['ruby'] as String?)?.isNotEmpty == true
          ? json['ruby'] as String?
          : null,
      pos: PartOfSpeech.fromString(posList.isNotEmpty ? posList.first : ''),
      meaningTranslated: _extractLocalizedMeaning(json['meanings']),
      exampleJp: (firstExample['jp'] ?? '').toString(),
      exampleTranslated: (firstExample['ko'] ?? '').toString(),
      exampleEn: (firstExample['en'] ?? '').toString(),
      level: JLPTLevel.fromString(
        levelList.isNotEmpty ? levelList.first : 'ETC',
      ),
      diaryId: diaryId,
      type: 'word',
      studyItemId: studyItemId,
      folderId: folderId,
    );
  }

  Future<VocabularyDetailInfo?> _fetchGrammarDetail(
      dynamic client, int id, String? userId) async {
    var response = await client
        .from('grammar')
        .select('id, title, reading, ruby, level, meaning, examples')
        .eq('id', id)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;

    final json = response as Map<String, dynamic>;
    String? diaryId;
    String? studyItemId;
    String? folderId;
    final title = (json['title'] ?? '').toString();

    final userRecResponse = await client
        .from('user_recommendations')
        .select('diary_id')
        .eq('grammar_id', id)
        .limit(1)
        .maybeSingle();
    diaryId = userRecResponse?['diary_id']?.toString();

    if (userId != null) {
      final studyItemResponse = await client
          .from('study_items')
          .select('id, folder_id')
          .eq('user_id', userId)
          .eq('type', 'grammar')
          .eq('word', title)
          .limit(1)
          .maybeSingle();
      studyItemId = studyItemResponse?['id']?.toString();
      folderId = studyItemResponse?['folder_id']?.toString();
    }

    final examples = (json['examples'] as List?) ?? [];
    Map<String, dynamic> firstExample = {};
    if (examples.isNotEmpty && examples.first is Map<String, dynamic>) {
      firstExample = examples.first as Map<String, dynamic>;
    }
    final level = (json['level'] ?? 'ETC').toString();

    return VocabularyDetailInfo(
      word: title,
      reading: (json['reading'] ?? '').toString(),
      ruby: (json['ruby'] as String?)?.isNotEmpty == true
          ? json['ruby'] as String?
          : null,
      pos: PartOfSpeech.etc,
      meaningTranslated: _extractLocalizedMeaning(json['meaning']),
      exampleJp: (firstExample['jp'] ?? '').toString(),
      exampleTranslated: (firstExample['ko'] ?? '').toString(),
      exampleEn: (firstExample['en'] ?? '').toString(),
      level: JLPTLevel.fromString(level),
      diaryId: diaryId,
      type: 'grammar',
      studyItemId: studyItemId,
      folderId: folderId,
    );
  }

  Future<Map<String, dynamic>?> fetchDiaryById(String diaryId) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return null;

    return client
        .from('diaries')
        .select(
            'id, content, corrected_content, correction_notes, content_furigana, corrected_content_furigana, created_at, feedback_status')
        .eq('id', diaryId)
        .limit(1)
        .maybeSingle();
  }
}

String _extractLocalizedMeaning(dynamic raw) {
  if (raw == null) return '';

  if (raw is Map) {
    final locale = getIt<GlobalBloc>().state.locale;
    final code = locale.languageCode;
    final map = raw.cast<String, dynamic>();

    String? value = map[code]?.toString();
    value ??= map['ko']?.toString();
    value ??= map['en']?.toString();
    value ??= map['ja']?.toString();
    return value ?? '';
  }

  if (raw is List) {
    return raw.isNotEmpty ? raw.first.toString() : '';
  }

  return raw.toString();
}
