enum JLPTLevel {
  n1('N1'),
  n2('N2'),
  n3('N3'),
  n4('N4'),
  n5('N5'),
  etc('ETC');

  final String nameString;
  const JLPTLevel(this.nameString);

  static JLPTLevel fromString(String val) {
    final upper = val.toUpperCase();
    return JLPTLevel.values.firstWhere(
      (e) => e.nameString == upper,
      orElse: () => JLPTLevel.etc,
    );
  }
}
