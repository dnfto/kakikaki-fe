import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_write_payload.freezed.dart';
part 'diary_write_payload.g.dart';

@freezed
class DiaryWritePayload with _$DiaryWritePayload {
  const factory DiaryWritePayload({
    required DateTime date,
    required String topic,
    required String content,
    String? diaryId, // 수정 시에만 값이 있음
  }) = _DiaryWritePayload;

  factory DiaryWritePayload.fromJson(Map<String, dynamic> json) =>
      _$DiaryWritePayloadFromJson(json);
}
