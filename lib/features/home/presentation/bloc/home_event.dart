part of 'home_bloc.dart';

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.started() = HomeStarted;
  const factory HomeEvent.dateChanged(DateTime date) = HomeDateChanged;

  // [Guideline 7] 안 쓰이던 HomeGenerateFeedback 삭제!

  const factory HomeEvent.loadDiaryForDate(DateTime date, bool forceRefresh) =
      HomeLoadDiaryForDate;
  const factory HomeEvent.refreshDiary() = HomeRefreshDiary;
  const factory HomeEvent.resetOnLogout() = HomeResetOnLogout;
  const factory HomeEvent.diaryClicked() = HomeDiaryClicked;
  const factory HomeEvent.resetSelectedDiaryFeedback() =
      HomeResetSelectedDiaryFeedback;
  const factory HomeEvent.clearFailedDiary() = HomeClearFailedDiary;
}
