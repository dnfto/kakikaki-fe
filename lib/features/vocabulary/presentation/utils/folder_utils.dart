import 'package:kakikaki/features/study/domain/model/folder.dart';

extension FolderListExtension on List<Folder> {
  /// 폴더 ID로 폴더 이름을 안전하게 찾아옵니다. (앱 전역 중복 코드 제거용)
  /// [uncategorizedFolderName] 폴더가 없거나 찾을 수 없을 때 표시할 이름 (다국어: context.l10n.folder_uncategorized)
  String getFolderName(String? folderId, [String? uncategorizedFolderName]) {
    // null이거나 앱에서 사용하는 가짜 ID일 경우 모두 '미분류'로 처리합니다.
    if (folderId == null || folderId == '__uncategorized__') {
      return uncategorizedFolderName ?? '미분류';
    }

    return firstWhere(
      (f) => f.id == folderId,
      orElse: () => Folder(
        id: '',
        // 폴더가 "삭제"되는 경우 내부 아이템은 미분류로 이동하므로,
        // 남아있는 folderId는 미분류로 표시합니다.
        name: uncategorizedFolderName ?? '미분류',
      ),
    ).name;
  }
}
