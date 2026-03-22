import 'package:freezed_annotation/freezed_annotation.dart';

part 'grammar_dto.freezed.dart';
part 'grammar_dto.g.dart';

@freezed
class GrammarDto with _$GrammarDto {
  const factory GrammarDto({
    required String id,
    required String title,
    required String reading,
    required String level,
    required String meaning,
    required String connection,
    @Default([]) List<String> examples,
    @Default('') String notes,
    @JsonKey(name: 'raw_text') required String rawText,
  }) = _GrammarDto;

  factory GrammarDto.fromJson(Map<String, dynamic> json) =>
      _$GrammarDtoFromJson(json);
}
