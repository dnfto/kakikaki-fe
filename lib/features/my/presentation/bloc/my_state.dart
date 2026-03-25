part of 'my_bloc.dart';

@freezed
class MyState with _$MyState {
  const factory MyState({
    // [Guideline 6] 앱 버전을 BLoC 상태로 관리
    @Default('') String appVersion,
    @Default(true) bool isAlarmEnabled,
    @Default(WeekdayLanguage.ko) WeekdayLanguage weekdayLanguage,
    @Default(CalendarStartingDay.sunday) CalendarStartingDay startingDay,
    @Default([]) inquiries,
    @Default(InquiryCategory.bug) InquiryCategory selectedCategory,
    @Default(false) bool isInquirySubmitting,
    @Default(false) bool isInquirySuccess,
    WithdrawalReason? selectedReason,
    @Default(false) bool isWithdrawalSuccess,
  }) = _MyState;
}
