part of 'diary_write_bloc.dart';

@freezed
class DiaryWriteState with _$DiaryWriteState {
  const factory DiaryWriteState({
    // [Guideline 8] 텍스트 필드로 충분한 content 삭제!
    @Default('') String topic,
    @Default('') String topicKo,
  }) = _DiaryWriteState;
}
