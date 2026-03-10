enum PartOfSpeech {
  noun('noun', '名詞', '명사', 'Noun'),
  verb('verb', '動詞', '동사', 'Verb'),
  adjective('adjective', '形容詞', '형용사', 'Adjective'),
  adverb('adverb', '副詞', '부사', 'Adverb'),
  pronoun('pronoun', '代名詞', '대명사', 'Pronoun'),
  particle('particle', '助詞', '조사', 'Particle'),
  expression('expression', '表現', '문형', 'Expression'),
  etc('etc', 'その他', '기타', 'Other');

  final String code;
  final String labelJp;
  final String labelKo;
  final String labelEn;

  const PartOfSpeech(this.code, this.labelJp, this.labelKo, this.labelEn);

  /// 현재 언어 코드에 따라 적절한 라벨 반환
  String getLabel(String languageCode) {
    switch (languageCode) {
      case 'ko':
        return labelKo;
      case 'ja':
        return labelJp;
      case 'en':
        return labelEn;
      default:
        return labelJp;
    }
  }

  static PartOfSpeech fromString(String val) {
    if (val.isEmpty) return PartOfSpeech.etc;

    if (val.contains('名詞')) return PartOfSpeech.noun;
    if (val.contains('動詞')) return PartOfSpeech.verb;
    if (val.contains('形容')) return PartOfSpeech.adjective;
    if (val.contains('副詞')) return PartOfSpeech.adverb;
    if (val.contains('代名')) return PartOfSpeech.pronoun;
    if (val.contains('助詞')) return PartOfSpeech.particle;
    if (val.contains('表現')) return PartOfSpeech.expression;

    final lower = val.toLowerCase();
    return PartOfSpeech.values.firstWhere(
      (e) => e.code == lower,
      orElse: () => PartOfSpeech.etc,
    );
  }
}
