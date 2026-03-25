part of 'diary_list_bloc.dart';

@freezed
class DiaryListEvent with _$DiaryListEvent {
  const factory DiaryListEvent.started() = DiaryListStarted;
  const factory DiaryListEvent.loadRequested() = DiaryListLoadRequested;
  const factory DiaryListEvent.feedbackRequested(DiaryListItem diary) =
      DiaryListFeedbackRequested;
  const factory DiaryListEvent.navigationHandled() = DiaryListNavigationHandled;
}
