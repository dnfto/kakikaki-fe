part of 'diary_processing_bloc.dart';

@freezed
class DiaryProcessingEvent with _$DiaryProcessingEvent {
  const factory DiaryProcessingEvent.started(DiaryWritePayload payload) =
      DiaryProcessingStarted;
  const factory DiaryProcessingEvent.completed(DiaryFeedbackResult result) =
      DiaryProcessingCompleted;
  const factory DiaryProcessingEvent.failed(String errorMessage) =
      DiaryProcessingFailed;
}
