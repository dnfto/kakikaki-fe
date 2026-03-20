import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';

part 'diary_recommendation_item.freezed.dart';
part 'diary_recommendation_item.g.dart';

class _PartOfSpeechConverter implements JsonConverter<PartOfSpeech, dynamic> {
  const _PartOfSpeechConverter();

  @override
  PartOfSpeech fromJson(dynamic json) =>
      PartOfSpeech.fromString((json ?? '').toString());

  @override
  dynamic toJson(PartOfSpeech object) => object.code;
}

class _JLPTLevelConverter implements JsonConverter<JLPTLevel, dynamic> {
  const _JLPTLevelConverter();

  @override
  JLPTLevel fromJson(dynamic json) =>
      JLPTLevel.fromString((json ?? '').toString());

  @override
  dynamic toJson(JLPTLevel object) => object.nameString;
}

@freezed
class DiaryRecommendationItem with _$DiaryRecommendationItem {
  const factory DiaryRecommendationItem({
    @Default('word') String type,
    required String word,
    required String reading,
    String? ruby,
    @_PartOfSpeechConverter() required PartOfSpeech pos,
    required String meaningTranslated,
    required String connection,
    required String exampleJp,
    required String exampleTranslated,
    required String exampleEn,
    @_JLPTLevelConverter() required JLPTLevel level,
  }) = _DiaryRecommendationItem;

  factory DiaryRecommendationItem.fromJson(Map<String, dynamic> json) =>
      _$DiaryRecommendationItemFromJson(json);

  factory DiaryRecommendationItem.fromJoinedData(Map<String, dynamic> map) {
    // 1. 'word' 혹은 'grammar' 알맹이 데이터 추출
    final type = map['item_type']?.toString() ?? 'word';
    final data = (type == 'word') ? map['word'] : map['grammar'];

    if (data == null)
      return const DiaryRecommendationItem(
          word: '',
          reading: '',
          pos: PartOfSpeech.etc,
          meaningTranslated: '',
          connection: '',
          exampleJp: '',
          exampleTranslated: '',
          exampleEn: '',
          level: JLPTLevel.etc);

    // 2. 의미 추출 (Map 구조 대응)
    final meaningMap = data['meanings'] ?? data['meaning'] ?? {};
    final String meaning = meaningMap['ko']?.toString() ?? '';

    // 3. 예문 추출 (리스트의 첫 번째 항목)
    final List examples = data['examples'] as List? ?? [];
    final firstEx = examples.isNotEmpty ? examples.first : {};

    return DiaryRecommendationItem(
      type: type,
      word: data['word'] ?? data['title'] ?? '',
      reading: data['reading']?.toString() ?? '',
      ruby: data['ruby']?.toString(),
      pos: PartOfSpeech.fromString(
          (data['pos'] is List && (data['pos'] as List).isNotEmpty)
              ? data['pos'][0].toString()
              : ''),
      meaningTranslated: meaning,
      connection: data['connection']?.toString() ?? '',
      exampleJp: firstEx['jp']?.toString() ?? '',
      exampleTranslated: firstEx['ko']?.toString() ?? '',
      exampleEn: firstEx['en']?.toString() ?? '',
      level: JLPTLevel.fromString(data['level']?.toString() ?? 'ETC'),
    );
  }
}
