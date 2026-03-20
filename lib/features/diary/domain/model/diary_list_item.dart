import 'package:freezed_annotation/freezed_annotation.dart';

part 'diary_list_item.freezed.dart';
part 'diary_list_item.g.dart';

DateTime _dateTimeFromJson(dynamic v) {
  try {
    return DateTime.parse((v ?? '').toString());
  } catch (_) {
    return DateTime.now();
  }
}

String _dateTimeToJson(DateTime date) => date.toIso8601String();

@freezed
class DiaryListItem with _$DiaryListItem {
  @JsonSerializable(fieldRename: FieldRename.snake)
  const factory DiaryListItem({
    @Default('') String id,
    @Default('') String content,
    String? correctedContent,
    dynamic correctionNotes,
    String? contentFurigana,
    String? correctedContentFurigana,
    String? feedbackStatus,
    // 커스텀 날짜 파싱 적용
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
    required DateTime createdAt,
  }) = _DiaryListItem;

  factory DiaryListItem.fromJson(Map<String, dynamic> json) =>
      _$DiaryListItemFromJson(json);
}
