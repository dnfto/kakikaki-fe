import 'package:freezed_annotation/freezed_annotation.dart';

part 'topic_dto.freezed.dart';
part 'topic_dto.g.dart';

@freezed
class TopicDto with _$TopicDto {
  const factory TopicDto({
    required int id,
    required String ja,
    required String ko,
    required String en,
  }) = _TopicDto;

  // JSON 직렬화/역직렬화 자동 생성
  factory TopicDto.fromJson(Map<String, dynamic> json) =>
      _$TopicDtoFromJson(json);
}
