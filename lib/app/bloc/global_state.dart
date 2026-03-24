part of 'global_bloc.dart';

/// 앱 전역 상태(언어 등)를 관리하고, 이를 Hive 데이터베이스에 저장하여 유지
@freezed
@HiveType(typeId: 0, adapterName: 'GlobalStateAdapter')
class GlobalState with _$GlobalState {
  const GlobalState._();
  const factory GlobalState({
    @Default('ko') @HiveField(0, defaultValue: 'ko') String languageCode,
    @Default('system') @HiveField(1, defaultValue: 'system') String themeMode,
    @HiveField(2) User? user,
    @HiveField(3) @Default(false) bool isLoggedIn,
    @HiveField(4) SocialType? socialType,
    @Default('skyBlue')
    @HiveField(5, defaultValue: 'skyBlue')
    String primaryColorType,
    @HiveField(6) @Default(false) bool isPremium,
    @HiveField(7) @Default(false) bool trialUsed,
    @Default(false) @HiveField(8, defaultValue: false) bool coachMarkHomeDone,
    @Default(false)
    @HiveField(9, defaultValue: false)
    bool coachMarkVocabularyDone,
    @Default(false) @HiveField(10, defaultValue: false) bool coachMarkStudyDone,

    /// 홈 출시 이벤트 팝업을 이미 본 사용자 ID (계정당 1회, 로컬 Hive)
    @Default(<String>[])
    @HiveField(11, defaultValue: <String>[])
    List<String> launchPromoShownUserIds,
  }) = _GlobalState;

  /// 단어장·학습 코치를 모두 봤는지(로컬)
  bool get areAllCoachMarksDone =>
      coachMarkVocabularyDone && coachMarkStudyDone;

  bool launchPromoShownForUser(String userId) =>
      launchPromoShownUserIds.contains(userId);

  Locale get locale => Locale(languageCode);

  ThemeMode get themeModeEnum {
    switch (themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
}
