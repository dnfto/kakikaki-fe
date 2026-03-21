import 'package:flutter/material.dart';
import 'package:kakikaki/core/extension/extension.dart';

enum VocabularyType {
  word,
  grammar;

  // JSON 파싱을 위한 헬퍼 (옵션)
  static VocabularyType fromString(String val) {
    // 라우트 query에서는 enum 전체(toString)로 들어올 수 있음:
    // 예: "VocabularyType.grammar" / "grammar"
    final normalized = val.split('.').last;
    return normalized == 'grammar' ? VocabularyType.grammar : VocabularyType.word;
  }
}

// UI 화면에서 사용할 다국어 라벨 변환 확장 메서드
extension VocabularyTypeLabel on VocabularyType {
  String label(BuildContext context) {
    switch (this) {
      case VocabularyType.grammar:
        return context.l10n.diary_feedback_chip_grammar;
      case VocabularyType.word:
        return context.l10n.vocabulary_detail_vocabulary_label;
    }
  }
}
