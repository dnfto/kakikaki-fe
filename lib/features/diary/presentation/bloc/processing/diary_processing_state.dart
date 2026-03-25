part of 'diary_processing_bloc.dart';

@freezed
class DiaryProcessingState with _$DiaryProcessingState {
  const factory DiaryProcessingState({
    @Default(false) bool isDone,
    @Default(false) bool isError,
    @Default('') String errorMessage,
    DiaryFeedbackResult? result,
  }) = _DiaryProcessingState;
}
