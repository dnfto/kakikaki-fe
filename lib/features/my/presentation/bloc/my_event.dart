part of 'my_bloc.dart';

@freezed
class MyEvent with _$MyEvent {
  // [Guideline 6] 마이페이지 전체 초기화 (앱 버전, 캘린더 설정 등 로드)
  const factory MyEvent.initialized() = MyInitialized;

  const factory MyEvent.nicknameChangeRequested(String newNickname) =
      MyNicknameChangeRequested;

  const factory MyEvent.calendarSettingsChanged({
    WeekdayLanguage? weekdayLanguage,
    CalendarStartingDay? startingDay,
  }) = MyCalendarSettingsChanged;
  const factory MyEvent.alarmToggled(bool isEnabled) = MyAlarmToggled;

  const factory MyEvent.inquiryListLoadRequested() = MyInquiryListLoadRequested;
  const factory MyEvent.inquiryCategoryChanged(InquiryCategory category) =
      MyInquiryCategoryChanged;

  const factory MyEvent.submitInquiryRequested({
    required String userId,
    required InquiryCategory category,
    required String title,
    required String content,
  }) = MySubmitInquiryRequested;

  const factory MyEvent.clearInquiryResult() = MyClearInquiryResult;

  const factory MyEvent.withdrawalRequested({
    required String reasonLabel,
  }) = MyWithdrawalRequested;
  const factory MyEvent.clearWithdrawalResult() = MyClearWithdrawalResult;
  const factory MyEvent.selectReason(WithdrawalReason reason) = MySelectReason;
}
