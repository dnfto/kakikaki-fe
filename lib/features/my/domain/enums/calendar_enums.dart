// 요일 표시 언어
enum WeekdayLanguage {
  ko(label: '한국어', code: 'ko'),
  en(label: 'English', code: 'en'),
  ja(label: '日本語', code: 'ja');

  final String label;
  final String code;

  const WeekdayLanguage({required this.label, required this.code});
}

// 캘린더 시작 요일
enum CalendarStartingDay {
  sunday(label: '일요일 시작', value: DateTime.sunday), // 7
  monday(label: '월요일 시작', value: DateTime.monday); // 1

  final String label;
  final int value;

  const CalendarStartingDay({required this.label, required this.value});
}
