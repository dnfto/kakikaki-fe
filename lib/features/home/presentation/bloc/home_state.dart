part of 'home_bloc.dart';

@freezed
class HomeState with _$HomeState {
  const HomeState._();
  const factory HomeState({
    required DateTime selectedDay,
    @Default(true) bool isDateSelected, // 초기값부터 오늘 날짜가 선택된 상태이므로 true로 변경

    // [Guideline 7] 안 쓰이던 번역/사전/추천문법 State 싹 다 삭제!

    @Default(<DateTime>{}) Set<DateTime> writtenDates,
    DiaryListItem? selectedDateDiary,
    DiaryListItem? failedDiaryToRetry,
    @Default(false) bool isLoadingDiary,
    @Default(false) bool isLoadingFeedback, // 피드백 진입 시 로딩
    DiaryFeedbackResult? selectedDiaryFeedback,
    @Default(<DateTime, DiaryListItem>{})
    Map<DateTime, DiaryListItem> diaryCache,
    Set<DateTime>? cachedWrittenDates,
    DateTime? writtenDatesCacheTime,
  }) = _HomeState;

  factory HomeState.initial() => HomeState(
        selectedDay: DateTime.now(),
        failedDiaryToRetry: null,
      );
}
