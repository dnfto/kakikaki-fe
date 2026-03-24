part of 'global_bloc.dart';

@freezed
class GlobalEvent with _$GlobalEvent {
  const factory GlobalEvent.changeLocale(Locale locale) = GlobalChangeLocale;
  const factory GlobalEvent.changeTheme(ThemeMode themeMode) =
      GlobalChangeTheme;
  const factory GlobalEvent.changePrimaryColor(
      PrimaryColorType primaryColorType) = GlobalChangePrimaryColor;

  const factory GlobalEvent.changeUser(User? user) = GlobalChangeUser;

  const factory GlobalEvent.updateUserNickname(String newNickname) =
      GlobalUpdateUserNickname;

  const factory GlobalEvent.changeSocialType(SocialType? socialType) =
      GlobalChangeSocialType;
  const factory GlobalEvent.changeToken({
    String? accessToken,
    String? refreshToken,
  }) = GlobalChangeToken;

  const factory GlobalEvent.checkPremiumStatus() = GlobalCheckPremiumStatus;
  const factory GlobalEvent.refreshUserInfo() = GlobalRefreshUserInfo;
  const factory GlobalEvent.logoutRequested() = GlobalLogoutRequested;
  const factory GlobalEvent.signOut() = GlobalSignOut;

  /// 코치마크 화면별 완료 (null이면 해당 필드 유지)
  const factory GlobalEvent.patchCoachMarks({
    bool? homeDone,
    bool? vocabularyDone,
    bool? studyDone,
  }) = GlobalPatchCoachMarks;

  /// 홈 출시 이벤트 안내 팝업을 봤음 (계정당 1회, 로컬 저장)
  const factory GlobalEvent.markLaunchPromoDialogShown() =
      GlobalMarkLaunchPromoDialogShown;
}
