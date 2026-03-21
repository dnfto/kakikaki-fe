import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';

part 'vocabulary_entry.freezed.dart';

/// 단어장 항목 모델 (Freezed 적용)
@freezed
class VocabularyEntry with _$VocabularyEntry {
  // 커스텀 getter(typeLabel)와 factory 메서드를 쓰기 위해 내부 생성자 추가
  const VocabularyEntry._();

  const factory VocabularyEntry({
    required int id,
    required String word,
    required String reading,
    String? ruby,
    required PartOfSpeech pos,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
    required String exampleEn,
    required JLPTLevel level,
    required VocabularyType type,
    String? studyItemId, // study_items 테이블의 id
    String? folderId, // 폴더 ID (null이면 미분류)
  }) = _VocabularyEntry;

  // vocabulary 테이블에서 변환
  factory VocabularyEntry.fromVocabJson(
      Map<String, dynamic> json, String type) {
    final posList =
        (json['pos'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final meaningsRaw = json['meanings'];
    final examples = (json['examples'] as List?) ?? [];
    Map<String, dynamic> firstExample = {};

    if (examples.isNotEmpty && examples.first is Map<String, dynamic>) {
      firstExample = examples.first as Map<String, dynamic>;
    }

    final levelList =
        (json['level'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final meaning = _extractLocalizedMeaning(meaningsRaw);
    final rubyRaw = json['ruby'] as String?;

    return VocabularyEntry(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      word: (json['word'] ?? '').toString(),
      reading: (json['reading'] ?? '').toString(),
      ruby: (rubyRaw != null && rubyRaw.isNotEmpty) ? rubyRaw : null,
      pos: PartOfSpeech.fromString(posList.isNotEmpty ? posList.first : ''),
      meaningTranslated: meaning,
      exampleJp: (firstExample['jp'] ?? '').toString(),
      exampleTranslated: (firstExample['ko'] ?? '').toString(),
      exampleEn: (firstExample['en'] ?? '').toString(),
      level:
          JLPTLevel.fromString(levelList.isNotEmpty ? levelList.first : 'ETC'),
      type: VocabularyType.fromString(type),
      studyItemId: json['study_item_id']?.toString(),
      folderId: json['folder_id']?.toString(),
    );
  }

  // grammar 테이블에서 변환
  factory VocabularyEntry.fromGrammarJson(
      Map<String, dynamic> json, String type) {
    final examples = (json['examples'] as List?) ?? [];
    Map<String, dynamic> firstExample = {};

    if (examples.isNotEmpty && examples.first is Map<String, dynamic>) {
      firstExample = examples.first as Map<String, dynamic>;
    }

    final level = (json['level'] ?? 'ETC').toString();
    final meaning = _extractLocalizedMeaning(json['meaning']);
    final rubyRaw = json['ruby'] as String?;

    return VocabularyEntry(
      id: json['id'] is int
          ? json['id'] as int
          : int.parse(json['id'].toString()),
      word: (json['title'] ?? '').toString(), // grammar는 title 필드 사용
      reading: (json['reading'] ?? '').toString(),
      ruby: (rubyRaw != null && rubyRaw.isNotEmpty) ? rubyRaw : null,
      pos: PartOfSpeech.etc, // grammar는 pos가 없으므로 etc로 설정
      meaningTranslated: meaning,
      exampleJp: (firstExample['jp'] ?? '').toString(),
      exampleTranslated: (firstExample['ko'] ?? '').toString(),
      exampleEn: (firstExample['en'] ?? '').toString(),
      level: JLPTLevel.fromString(level),
      type: VocabularyType.fromString(type),
      studyItemId: json['study_item_id']?.toString(),
      folderId: json['folder_id']?.toString(),
    );
  }
}

// [수정됨] 모든 if문에 중괄호 {}를 넣어서 린트 에러(curly_braces_in_flow_control_structures) 해결!
String _extractLocalizedMeaning(dynamic raw) {
  if (raw == null) {
    return '';
  }

  // 새 구조: { ko: "...", en: "...", ja: "..." }
  if (raw is Map) {
    final locale = getIt<GlobalBloc>().state.locale;
    final code = locale.languageCode;
    final map = raw.cast<String, dynamic>();

    String? value = map[code]?.toString();
    value ??= map['ko']?.toString();
    value ??= map['en']?.toString();
    value ??= map['ja']?.toString();

    if (value != null) {
      return value;
    } else {
      return '';
    }
  }

  // 이전 구조: 리스트 또는 단일 문자열
  if (raw is List) {
    if (raw.isNotEmpty) {
      return raw.first.toString();
    } else {
      return '';
    }
  }

  return raw.toString();
}
