import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/notification.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/features/my/domain/enums/calendar_enums.dart';
import 'package:kakikaki/features/my/domain/enums/inquiry_category.dart';
import 'package:kakikaki/features/my/domain/enums/withdrawal_reasons.dart';
import 'package:kakikaki/features/my/domain/repository/inquiry_repository.dart';
import 'package:kakikaki/features/my/domain/repository/user_repository.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

part 'my_bloc.freezed.dart';
part 'my_event.dart';
part 'my_state.dart';

@injectable
class MyBloc extends BaseBloc<MyEvent, MyState> {
  MyBloc() : super(const MyState()) {
    onWithoutAutoLoading<MyInitialized>(_onInitialized);

    onWithoutAutoLoading<MySelectReason>(
        (e, emit) => emit(state.copyWith(selectedReason: e.reason)));
    onWithoutAutoLoading<MyWithdrawalRequested>(_onWithdrawalRequested);
    onWithoutAutoLoading<MyClearWithdrawalResult>(
        (e, emit) => emit(state.copyWith(isWithdrawalSuccess: false)));

    onWithoutAutoLoading<MyCalendarSettingsChanged>(_onCalendarSettingsChanged);
    onWithoutAutoLoading<MyAlarmToggled>(_onAlarmToggled);

    on<MyInquiryListLoadRequested>(_onInquiryListLoadRequested);
    onWithoutAutoLoading<MyInquiryCategoryChanged>(
        (e, emit) => emit(state.copyWith(selectedCategory: e.category)));
    onWithoutAutoLoading<MySubmitInquiryRequested>(_onSubmitInquiry);
    onWithoutAutoLoading<MyClearInquiryResult>(
        (e, emit) => emit(state.copyWith(isInquirySuccess: false)));

    onWithoutAutoLoading<MyNicknameChangeRequested>(_onNicknameChangeRequested);
  }

  final UserRepository userRepository = getIt<UserRepository>();
  final InquiryRepository inquiryRepository = getIt<InquiryRepository>();
  final GlobalBloc globalBloc = getIt<GlobalBloc>();

  // [Guideline 6] UI에 흩어져 있던 SharedPrefs와 PackageInfo 로드 로직을 BLoC으로 이관!
  Future<void> _onInitialized(
      MyInitialized event, Emitter<MyState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isAlarmEnabled =
        prefs.getBool(NotificationConstants.dailyReminderEnabled) ?? true;
    final savedLangName =
        prefs.getString('calendar_weekday_language') ?? WeekdayLanguage.ko.name;
    final savedDayName = prefs.getString('calendar_starting_day') ??
        CalendarStartingDay.sunday.name;

    final langEnum = WeekdayLanguage.values.firstWhere(
        (e) => e.name == savedLangName,
        orElse: () => WeekdayLanguage.ko);
    final dayEnum = CalendarStartingDay.values.firstWhere(
        (e) => e.name == savedDayName,
        orElse: () => CalendarStartingDay.sunday);

    String appVersion = '';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    emit(state.copyWith(
        isAlarmEnabled: isAlarmEnabled,
        weekdayLanguage: langEnum,
        startingDay: dayEnum,
        appVersion: appVersion));
  }

  Future<void> _onAlarmToggled(
      MyAlarmToggled event, Emitter<MyState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        NotificationConstants.dailyReminderEnabled, event.isEnabled);
    emit(state.copyWith(isAlarmEnabled: event.isEnabled));
  }

  // 캘린더 설정 변경 시 BLoC에서 직접 디바이스 저장
  Future<void> _onCalendarSettingsChanged(
      MyCalendarSettingsChanged event, Emitter<MyState> emit) async {
    final prefs = await SharedPreferences.getInstance();

    if (event.weekdayLanguage != null) {
      await prefs.setString(
          'calendar_weekday_language', event.weekdayLanguage!.name);
    }
    if (event.startingDay != null) {
      await prefs.setString('calendar_starting_day', event.startingDay!.name);
    }

    emit(state.copyWith(
      weekdayLanguage: event.weekdayLanguage ?? state.weekdayLanguage,
      startingDay: event.startingDay ?? state.startingDay,
    ));
  }

  Future<void> _onInquiryListLoadRequested(
      MyInquiryListLoadRequested event, Emitter<MyState> emit) async {
    final userId = globalBloc.state.user?.id;
    if (userId == null || !globalBloc.state.isLoggedIn) {
      emit(state.copyWith(inquiries: []));
      return;
    }
    final inquiries = await inquiryRepository.getInquiries(userId: userId);
    emit(state.copyWith(inquiries: inquiries));
  }

// my_bloc.dart
  Future<void> _onWithdrawalRequested(
      MyWithdrawalRequested event, Emitter<MyState> emit) async {
    await runBlocCatching(
      handleLoading: true,
      doOnEventStart: () => emit(state.copyWith(isWithdrawalSuccess: false)),
      action: () async {
        // 고민 해결! BLoC은 넘어온 텍스트만 서버로 보냅니다.
        await userRepository.deleteAccount(reason: event.reasonLabel);
      },
      doOnSuccess: (_) {
        globalBloc.add(const GlobalEvent.logoutRequested());
        emit(state.copyWith(isWithdrawalSuccess: true));
      },
    );
  }

  Future<void> _onSubmitInquiry(
      MySubmitInquiryRequested event, Emitter<MyState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      doOnEventStart: () => emit(
          state.copyWith(isInquirySubmitting: true, isInquirySuccess: false)),
      action: () async {
        await inquiryRepository.submitInquiry(
          userId: event.userId,
          category: event.category.code,
          title: event.title,
          content: event.content,
        );
      },
      doOnSuccess: (_) {
        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .inquiry_toast_thanks);
        emit(
            state.copyWith(isInquirySubmitting: false, isInquirySuccess: true));
      },
      doOnError: (e) => emit(state.copyWith(isInquirySubmitting: false)),
    );
  }

  Future<void> _onNicknameChangeRequested(
      MyNicknameChangeRequested event, Emitter<MyState> emit) async {
    final userId = globalBloc.state.user?.id;
    if (userId == null) return;

    await runBlocCatching(
      handleLoading: true,
      action: () async => await userRepository.updateNickname(
          userId: userId, newNickname: event.newNickname),
      doOnSuccess: (_) {
        globalBloc.add(GlobalEvent.updateUserNickname(event.newNickname));
        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .my_toast_nickname_changed);
      },
    );
  }
}
