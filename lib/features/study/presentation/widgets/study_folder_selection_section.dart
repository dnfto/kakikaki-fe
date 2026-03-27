import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';

class StudyFolderSelectionSection extends StatelessWidget {
  const StudyFolderSelectionSection({
    super.key,
    required this.folders,
    required this.isPremium,
    required this.onTapUncategorized,
    required this.onTapFolder,
    this.onCreateFolder,
    this.onEditFolder,
    this.onDeleteFolder,
    this.uncategorizedFolderKey,
  });

  final List<Folder> folders;
  final bool isPremium;
  final VoidCallback onTapUncategorized;
  final ValueChanged<Folder> onTapFolder;
  final VoidCallback? onCreateFolder;
  final ValueChanged<Folder>? onEditFolder;
  final ValueChanged<Folder>? onDeleteFolder;

  /// 온보딩(튜토리얼)에서 미분류 타일 하이라이트용
  final GlobalKey? uncategorizedFolderKey;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Text(context.l10n.study_folder_selection_title,
            style: context.h3_700Style),
        const SizedBox(height: 6),
        Text(
          context.l10n.study_folder_selection_subtitle,
          style: context.h6_400Style.copyWith(color: Palette.gray60),
        ),
        const SizedBox(height: 14),
        uncategorizedFolderKey != null
            ? KeyedSubtree(
                key: uncategorizedFolderKey,
                child: _StudyFolderTile(
                  title: context.l10n.study_folder_uncategorized,
                  onTap: onTapUncategorized,
                ),
              )
            : _StudyFolderTile(
                title: context.l10n.study_folder_uncategorized,
                onTap: onTapUncategorized,
              ),
        const SizedBox(height: 8),
        ...folders.map(
          (folder) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _StudyFolderTile(
              title: folder.name,
              onTap: () => onTapFolder(folder),
              iconColor: context.palette.primary,
              isPremium: isPremium,
              onEdit: isPremium && onEditFolder != null
                  ? () => onEditFolder!(folder)
                  : null,
              onDelete: isPremium && onDeleteFolder != null
                  ? () => onDeleteFolder!(folder)
                  : null,
            ),
          ),
        ),
        if (onCreateFolder != null) ...[
          const SizedBox(height: 8),
          CommonElevatedButton(
            text: context.l10n.study_new_folder_title,
            onPressed: onCreateFolder,
          ),
        ],
      ],
    );
  }
}

class _StudyFolderTile extends StatelessWidget {
  const _StudyFolderTile({
    required this.title,
    required this.onTap,
    this.isPremium = false,
    this.onEdit,
    this.onDelete,
    this.iconColor,
  });

  final String title;

  final VoidCallback onTap;
  final bool isPremium;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 폴더 아이콘 색 (null이면 기본 onSurface 사용)
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Palette.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.folder_rounded,
                color: iconColor ?? context.palette.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: context.h6_700Style),
              ),
              if (isPremium && (onEdit != null || onDelete != null))
                Row(
                  children: [
                    CommonIconButton(
                        primary: context.palette.onSurface,
                        icon: Icon(Icons.edit),
                        onPressed: onEdit!),
                    SizedBox(width: 16),
                    CommonIconButton(
                        primary: context.palette.onSurface,
                        icon: Icon(Icons.delete),
                        onPressed: onDelete!)
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}
