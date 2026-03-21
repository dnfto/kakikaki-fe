import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_result.freezed.dart';

/// 복습 결과 모델 (Dart FSRS 패키지 맞춤형)
@freezed
class ReviewResult with _$ReviewResult {
  const factory ReviewResult({
    required double newStability,
    required double newDifficulty,
    int? newStep,
    required int newElapsedDays,
    required int newScheduledDays,
    required int newLapses,
    required int newState, // 1: learning, 2: review, 3: relearning
    required int newRepetitions,
    required DateTime nextReviewDate,
    DateTime? lastReviewDate,
    required String intervalText,
  }) = _ReviewResult;
}
