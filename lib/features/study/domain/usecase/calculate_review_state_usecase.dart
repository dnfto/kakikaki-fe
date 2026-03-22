import 'dart:math';

import 'package:fsrs/fsrs.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/domain/model/review_level.dart';
import 'package:kakikaki/features/study/domain/model/review_result.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

/// FSRS 알고리즘 기반 복습 상태 계산 UseCase
@lazySingleton
class CalculateReviewStateUseCase {
  final Scheduler _scheduler = Scheduler();

  ReviewResult call(StudyEntry entry, ReviewLevel level) {
    final now = DateTime.now().toUtc();

    Rating rating;
    switch (level) {
      case ReviewLevel.again:
        rating = Rating.again;
        break;
      case ReviewLevel.hard:
        rating = Rating.hard;
        break;
      case ReviewLevel.good:
        rating = Rating.good;
        break;
      case ReviewLevel.easy:
        rating = Rating.easy;
        break;
    }

    int stateValue = entry.state;
    if (stateValue < 1 || stateValue > 3) stateValue = 1;

    var currentCard = Card(
      cardId: entry.id.hashCode,
      state: State.fromValue(stateValue),
      step: entry.step,
      stability: (entry.stability != null && entry.stability! > 0)
          ? entry.stability
          : null,
      difficulty: (entry.difficulty != null && entry.difficulty! > 0)
          ? entry.difficulty
          : null,
      due: entry.nextReviewDate.toUtc(),
      lastReview: entry.lastReviewDate?.toUtc(),
    );

    final result =
        _scheduler.reviewCard(currentCard, rating, reviewDateTime: now);
    final nextCard = result.card;

    int newReps = entry.repetitions + 1;
    int newLapses = entry.lapses;
    if (rating == Rating.again) {
      newLapses += 1;
    }

    int scheduledDays = max(0, nextCard.due.difference(now).inDays);

    return ReviewResult(
      newStability: nextCard.stability ?? 0.0,
      newDifficulty: nextCard.difficulty ?? 0.0,
      newStep: nextCard.step,
      newElapsedDays: 0,
      newScheduledDays: scheduledDays,
      newLapses: newLapses,
      newState: nextCard.state.value,
      newRepetitions: newReps,
      nextReviewDate: nextCard.due.toLocal(),
      lastReviewDate: nextCard.lastReview?.toLocal(),
      intervalText: _getIntervalText(nextCard.due, now),
    );
  }

  String _getIntervalText(DateTime due, DateTime now) {
    final duration = due.difference(now);

    if (duration.isNegative || duration.inSeconds < 30) {
      return '잠시 후';
    }
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes}분 후';
    }
    if (duration.inHours < 24) {
      return '${duration.inHours}시간 후';
    }
    if (duration.inDays < 7) {
      return '${duration.inDays}일 후';
    }
    if (duration.inDays < 30) {
      final weeks = (duration.inDays / 7).floor();
      return '$weeks주 후';
    }
    if (duration.inDays < 365) {
      final months = (duration.inDays / 30).floor();
      return '$months개월 후';
    }
    final years = (duration.inDays / 365).floor();
    return '$years년 후';
  }
}
