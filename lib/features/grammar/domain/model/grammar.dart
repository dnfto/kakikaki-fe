import 'package:freezed_annotation/freezed_annotation.dart';

part 'grammar.freezed.dart';

// json 관련 코드(@JsonKey, fromJson)가 전혀 없는 순수한 비즈니스 객체
@freezed
class Grammar with _$Grammar {
  const factory Grammar({
    required String id,
    required String title,
    required String reading,
    required String level,
    required String meaning,
    required String connection,
    @Default([]) List<String> examples,
    @Default('') String notes,
    required String rawText, // 카멜케이스 사용
  }) = _Grammar;
}
