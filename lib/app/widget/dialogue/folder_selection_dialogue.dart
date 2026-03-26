import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/button/common_elevated_button.dart'; // 공통 버튼 임포트
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';

/// 앱 전역에서 사용하는 공통 폴더 선택 다이얼로그
class FolderSelectionDialog {
  FolderSelectionDialog._();

  // 결과를 구분하기 위한 특수 키워드
  static const String uncategorized = '__uncategorized__';
  static const String createNew = '__create_new__';

  static Future<String?> show({
    required BuildContext context,
    required List<Folder> folders,
  }) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: dialogContext.palette.surface,
          shape: RoundedRectangleBorder(
            borderRadius: Dimens.defaultDialogueRadius,
          ),
          child: Container(
            width: dialogContext.screenWidth * 0.9,
            padding: EdgeInsets.all(dialogContext.screenWidth * 0.05),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '폴더 선택',
                  style: dialogContext.h5_700Style,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: dialogContext.screenHeight * 0.4,
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // 미분류 옵션
                      InkWell(
                        onTap: () =>
                            Navigator.of(dialogContext).pop(uncategorized),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.folder_rounded,
                                  color: Palette.gray70),
                              const SizedBox(width: 12),
                              Text(
                                dialogContext.l10n.study_folder_uncategorized,
                                style: dialogContext.h6_400Style,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 동적 폴더 목록
                      ...folders.map(
                        (folder) => InkWell(
                          onTap: () =>
                              Navigator.of(dialogContext).pop(folder.id),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            child: Row(
                              children: [
                                Icon(Icons.folder_rounded,
                                    color: dialogContext.palette.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    folder.name,
                                    style: dialogContext.h6_400Style,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // [Guideline 9] 하드코딩된 위젯 대신 공통 Elevated 버튼 적용!
                CommonElevatedButton(
                  text: '+ 새 폴더 만들기',
                  backgroundColor: dialogContext.palette.primary, // 강조 컬러 적용
                  enabledTextColor: dialogContext.palette.onPrimary,
                  onPressed: () => Navigator.of(dialogContext).pop(createNew),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
