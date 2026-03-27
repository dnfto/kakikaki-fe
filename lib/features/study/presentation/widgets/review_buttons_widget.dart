import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/button/common_elevated_button.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/domain/model/review_level.dart';

import 'package:kakikaki/features/study/domain/model/review_result.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

/// 복습 버튼들 위젯
class ReviewButtonsWidget extends StatelessWidget {
  const ReviewButtonsWidget({
    super.key,
    required this.entry,
    required this.calculateReview,
    required this.onReview,
  });

  final StudyEntry entry;
  final ReviewResult Function(StudyEntry entry, ReviewLevel level)
      calculateReview;
  final void Function(ReviewLevel level, ReviewResult result) onReview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _ReviewButton(
                entry: entry,
                level: ReviewLevel.again,
                calculateReview: calculateReview,
                onReview: onReview,
                // backgroundColor: context.palette.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReviewButton(
                entry: entry,
                level: ReviewLevel.hard,
                calculateReview: calculateReview,
                onReview: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReviewButton(
                entry: entry,
                level: ReviewLevel.good,
                calculateReview: calculateReview,
                onReview: onReview,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ReviewButton(
                entry: entry,
                level: ReviewLevel.easy,
                isElevated: true,
                calculateReview: calculateReview,
                onReview: onReview,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 개별 복습 버튼
class _ReviewButton extends StatelessWidget {
  const _ReviewButton({
    required this.entry,
    required this.level,
    required this.calculateReview,
    required this.onReview,
    this.isElevated = false,
  });

  final StudyEntry entry;
  final ReviewLevel level;
  final ReviewResult Function(StudyEntry entry, ReviewLevel level)
      calculateReview;
  final void Function(ReviewLevel level, ReviewResult result) onReview;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    final result = calculateReview(entry, level);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isElevated)
          CommonElevatedButton(
            textStyle:
                context.h8_600Style.copyWith(color: context.palette.surface),
            text: level.getLabel(context.l10n),
            onPressed: () => onReview(level, result),
            backgroundColor: context.palette.onSurface,
            enabledTextColor: context.palette.surface,
            height: 40,
            isExpandedWidth: true,
          )
        else
          CommonElevatedButton(
            textStyle:
                context.h8_600Style.copyWith(color: context.palette.surface),
            text: level.getLabel(context.l10n),
            onPressed: () => onReview(level, result),
            backgroundColor: context.palette.onSurface,
            enabledTextColor: context.palette.surface,
            height: 40,
            isExpandedWidth: true,
          ),
        const SizedBox(height: 4),
        Text(
          result.intervalText,
          style: context.h8_400Style.copyWith(
            color: Palette.gray50,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
