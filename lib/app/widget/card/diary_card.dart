import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';

class DiaryCard extends StatelessWidget {
  const DiaryCard({
    super.key,
    required this.diary,
    required this.onTap,
    required this.isProcessing,
    required this.isFailed,
    this.date,
  });

  final DiaryListItem diary;
  final VoidCallback onTap;
  final bool isProcessing;
  final bool isFailed;
  final String? date;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Palette.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.gray20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.book,
                  size: 20,
                  color: context.palette.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  date ?? context.l10n.diary_card_default_title,
                  style: context.h6_700Style,
                ),
                const Spacer(),
                // UI 분기
                if (isProcessing) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.palette.primary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.diary_card_status_analyzing,
                    style: context.h8_400Style.copyWith(
                      color: Palette.gray50,
                    ),
                  ),
                ] else if (isFailed) ...[
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: context.palette.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    context.l10n.diary_card_status_failed,
                    style: context.h8_400Style.copyWith(
                      color: context.palette.error,
                    ),
                  ),
                ] else ...[
                  Text(
                    context.l10n.diary_card_view_feedback,
                    style: context.h8_600Style.copyWith(
                      color: context.palette.primary,
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Palette.gray40,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              diary.content.length > 100
                  ? diary.content.substring(0, 100)
                  : diary.content,
              style: context.h7_400Style.copyWith(
                color: Palette.gray70,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
