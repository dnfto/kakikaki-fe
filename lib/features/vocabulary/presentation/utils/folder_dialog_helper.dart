import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/app/widget/dialogue/folder_selection_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/premium_dialog_hleper.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';

class FolderDialogHelper {
  FolderDialogHelper._();

  /// 프리미엄 체크와 폴더 선택 팝업 호출을 한 번에 처리하는 공통 함수
  /// [showToast]는 BaseBloc의 addToastMessage 등을 넘겨주면 됩니다.
  static Future<String?> showWithPremiumCheck({
    required BuildContext context,
    required List<Folder> folders,
    required Function(String) showToast, // 이건 이제 안 쓰지만 구조상 둬도 무방함
  }) async {
    if (!getIt<GlobalBloc>().state.isPremium) {
      await PremiumDialogHelper.showPremiumGuide(
        context,
        message: context.l10n.vocabulary_folder_premium,
      );
      return null;
    }
    return await FolderSelectionDialog.show(context: context, folders: folders);
  }
}
