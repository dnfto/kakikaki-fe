import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/core/network/base_repository.dart';
import 'package:kakikaki/features/diary/data/source/diary_recommendation_remote_data_source.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';
import 'package:kakikaki/features/diary/domain/repository/diary_recommendation_repository.dart';

@Injectable(as: DiaryRecommendationRepository)
class DiaryRecommendationRepositoryImpl extends BaseRepository
    implements DiaryRecommendationRepository {
  DiaryRecommendationRepositoryImpl(this._dataSource)
      : super('diary/recommendations');

  final DiaryRecommendationRemoteDataSource _dataSource;

  @override
  Future<List<DiaryRecommendationItem>> fetchRecommendationsByDiaryId({
    required String diaryId,
  }) async {
    final raw = await _dataSource.fetchRecommendations(diaryId);

    // [Guideline 4] 빈 리스트 만들어놓고 for문 돌리며 add() 하던 구조를 map + whereType으로 100% 함수형으로 대체
    return raw.uniqueRows
        .map((rec) {
          final wordId = rec['word_id'] as int?;
          final grammarId = rec['grammar_id'] as int?;

          if (wordId != null && raw.vocabularyById.containsKey(wordId)) {
            final item = raw.vocabularyById[wordId]!;
            final posList =
                (item['pos'] as List?)?.map((e) => e.toString()).toList() ?? [];
            final examples = (item['examples'] as List?) ?? [];
            final firstExample =
                (examples.isNotEmpty && examples.first is Map<String, dynamic>)
                    ? examples.first as Map<String, dynamic>
                    : <String, dynamic>{};
            final levelList =
                (item['level'] as List?)?.map((e) => e.toString()).toList() ??
                    [];

            return DiaryRecommendationItem(
              type: 'word',
              word: (item['word'] ?? '').toString(),
              reading: (item['reading'] ?? '').toString(),
              ruby: (item['ruby'] as String?)?.isNotEmpty == true
                  ? item['ruby'] as String?
                  : null,
              pos: PartOfSpeech.fromString(
                  posList.isNotEmpty ? posList.first : ''),
              meaningTranslated: _extractLocalizedMeaning(item['meanings']),
              connection: '',
              exampleJp: (firstExample['jp'] ?? '').toString(),
              exampleTranslated: (firstExample['ko'] ?? '').toString(),
              exampleEn: (firstExample['en'] ?? '').toString(),
              level: JLPTLevel.fromString(
                  levelList.isNotEmpty ? levelList.first : 'ETC'),
            );
          } else if (grammarId != null &&
              raw.grammarById.containsKey(grammarId)) {
            final item = raw.grammarById[grammarId]!;
            final examples = (item['examples'] as List?) ?? [];
            final firstExample =
                (examples.isNotEmpty && examples.first is Map<String, dynamic>)
                    ? examples.first as Map<String, dynamic>
                    : <String, dynamic>{};
            final level = (item['level'] ?? 'ETC').toString();

            return DiaryRecommendationItem(
              type: 'grammar',
              word: (item['title'] ?? '').toString(),
              reading: (item['reading'] ?? '').toString(),
              ruby: (item['ruby'] as String?)?.isNotEmpty == true
                  ? item['ruby'] as String?
                  : null,
              pos: PartOfSpeech.etc,
              meaningTranslated: _extractLocalizedMeaning(item['meaning']),
              connection: '',
              exampleJp: (firstExample['jp'] ?? '').toString(),
              exampleTranslated: (firstExample['ko'] ?? '').toString(),
              exampleEn: (firstExample['en'] ?? '').toString(),
              level: JLPTLevel.fromString(level),
            );
          }
          return null; // 파싱 실패한 항목은 버림
        })
        .whereType<DiaryRecommendationItem>()
        .toList();
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
