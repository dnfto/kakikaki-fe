import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';

part 'vocabulary_detail_info.freezed.dart';

@freezed
class VocabularyDetailInfo with _$VocabularyDetailInfo {
  const factory VocabularyDetailInfo({
    required String word,
    required String reading,
    String? ruby,
    required PartOfSpeech pos,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
    required String exampleEn,
    required JLPTLevel level,
    required String type,
    required String? diaryId,
    String? studyItemId,
    String? folderId,
  }) = _VocabularyDetailInfo;
}
