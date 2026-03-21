import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/features/study/domain/model/review_result.dart';

part 'study_entry.freezed.dart';

/// 학습 항목 엔티티 (FSRS 알고리즘 적용)
@freezed
class StudyEntry with _$StudyEntry {
  const StudyEntry._();
  const factory StudyEntry({
    required String id,
    required String type,
    required String word,
    required String reading,
    String? ruby,
    required PartOfSpeech pos,
    required String meaningTranslated,
    required String exampleJp,
    required String exampleTranslated,
    required JLPTLevel level,
    @Default('') String connection,

    // FSRS 핵심 데이터
    @Default(1) int state, // 1: learning (기본값)
    int? step,
    double? stability,
    double? difficulty,
    @Default(0) int elapsedDays,
    @Default(0) int scheduledDays,
    @Default(0) int lapses,
    @Default(0) int repetitions,
    required DateTime nextReviewDate,
    DateTime? lastReviewDate,
  }) = _StudyEntry;

  // 기존에 작성하신 안전한 수동 파싱 로직 유지 (g.dart 필요 없음)
  factory StudyEntry.fromJson(Map<String, dynamic> json) {
    final posStr = (json['pos'] ?? '').toString();

    return StudyEntry(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'word').toString(),
      word: (json['word'] ?? '').toString(),
      reading: (json['reading'] ?? '').toString(),
      ruby: (json['ruby'] as String?)?.isNotEmpty == true
          ? json['ruby'] as String?
          : null,
      pos: PartOfSpeech.fromString(posStr),
      meaningTranslated: (json['meaning_translated'] ?? '').toString(),
      exampleJp: (json['example_jp'] ?? '').toString(),
      exampleTranslated: (json['example_translated'] ?? '').toString(),
      level: JLPTLevel.fromString((json['jlpt'] ?? 'ETC').toString()),
      connection: (json['connection'] ?? '').toString(),

      // FSRS 필드 DB 매핑
      state: int.tryParse((json['state'] ?? '1').toString()) ?? 1,
      step: json['step'] != null ? int.tryParse(json['step'].toString()) : null,
      stability: json['stability'] != null
          ? double.tryParse(json['stability'].toString())
          : null,
      difficulty: json['difficulty'] != null
          ? double.tryParse(json['difficulty'].toString())
          : null,
      elapsedDays: int.tryParse((json['elapsed_days'] ?? '0').toString()) ?? 0,
      scheduledDays:
          int.tryParse((json['scheduled_days'] ?? '0').toString()) ?? 0,
      lapses: int.tryParse((json['lapses'] ?? '0').toString()) ?? 0,
      repetitions: int.tryParse((json['repetitions'] ?? '0').toString()) ?? 0,

      // 날짜 처리
      nextReviewDate: json['next_review_date'] != null
          ? DateTime.tryParse(json['next_review_date'].toString()) ??
              DateTime.now()
          : DateTime.now(),
      lastReviewDate: json['last_review_date'] != null
          ? DateTime.tryParse(json['last_review_date'].toString())
          : null,
    );
  }
  // 복습 결과를 받아서 자신을 업데이트하는 헬퍼 메서드!
  StudyEntry applyReview(ReviewResult result) {
    return copyWith(
      state: result.newState,
      step: result.newStep,
      stability: result.newStability,
      difficulty: result.newDifficulty,
      elapsedDays: result.newElapsedDays,
      scheduledDays: result.newScheduledDays,
      lapses: result.newLapses,
      repetitions: result.newRepetitions,
      nextReviewDate: result.nextReviewDate,
      lastReviewDate: result.lastReviewDate,
    );
  }
}
