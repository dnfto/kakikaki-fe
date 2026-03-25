part of 'diary_write_bloc.dart';

@freezed
class DiaryWriteEvent with _$DiaryWriteEvent {
  const factory DiaryWriteEvent.topicInitialized(String topic, String topicKo) =
      DiaryWriteTopicInitialized;
  const factory DiaryWriteEvent.topicChangeRequested() =
      DiaryWriteTopicChangeRequested;
}
