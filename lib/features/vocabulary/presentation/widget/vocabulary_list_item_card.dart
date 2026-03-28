import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/app/widget/view/common_chip.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_entry.dart';

import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';

class VocabularyListItemCard extends StatelessWidget {
  const VocabularyListItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    required this.folderName,
    required this.onTap,
    this.onLongPress,
    required this.onUnbookmarkTapped,
    required this.onCheckTapped,
  });

  final VocabularyEntry item;
  final bool isSelected;
  final bool isSelectionMode;
  final String folderName;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onUnbookmarkTapped;
  final VoidCallback onCheckTapped;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? context.palette.primary.withExactOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: context.palette.primary, width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CommonChip(label: folderName, icon: Icons.folder_rounded),
                  const SizedBox(width: 6),
                  CommonChip(label: item.type.label(context)),
                  const SizedBox(width: 6),
                  CommonChip(label: item.level.nameString),
                  const Spacer(),
                  if (isSelectionMode)
                    GestureDetector(
                      onTap: onCheckTapped,
                      child: Icon(
                        Icons.check_rounded,
                        color: isSelected
                            ? context.palette.primary
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: onUnbookmarkTapped,
                      child: Icon(Icons.bookmark,
                          color: context.palette.primary, size: 20),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              RubyText(
                text: item.ruby ?? item.word,
                baseStyle: context.h3_700Style,
              ),
              if (item.meaningTranslated.isNotEmpty) ...[
                const SizedBox(height: 8),
                RubyText(
                  text: item.meaningTranslated,
                  baseStyle:
                      context.h6_400Style.copyWith(color: Palette.gray70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
