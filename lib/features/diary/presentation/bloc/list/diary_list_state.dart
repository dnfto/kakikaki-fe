part of 'diary_list_bloc.dart';

@freezed
class DiaryListState with _$DiaryListState {
  const factory DiaryListState({
    @Default([]) List<DiaryListItem> diaries,
    DiaryFeedbackResult? navigateToFeedbackPayload,
  }) = _DiaryListState;
}
