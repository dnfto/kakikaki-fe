import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/widget/calendar/home_calendar_widget.dart';
import 'package:kakikaki/app/widget/card/diary_card.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/diary_usage_helper.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/date_format_utils.dart';
import 'package:kakikaki/core/utils/permission_request_handler.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/core/utils/weekday_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_write_payload.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

import '../../../../app/widget/button/common_elevated_button.dart';
import '../bloc/home_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState
    extends BaseScaffoldPageState<HomePage, HomeBloc, HomeState>
    with WidgetsBindingObserver {
  _HomePageState()
      : super(
            backgroundColor: Palette.gray10,
            horizontalMargin: 0,
            verticalMargin: 0,
            automaticallyImplyLeading: false);

  late StreamSubscription<GlobalState> _globalBlocSubscription;
  bool _isInitialLoad = true;

  /// 출시 이벤트 팝업 스케줄 중복 방지
  bool _launchPromoDialogScheduled = false;

  @override
  String get appBarTitle {
    final globalState = getIt<GlobalBloc>().state;
    final l10n = lookupAppLocalizations(globalState.locale);
    final rawName = globalState.user?.name?.trim();
    final userName = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : l10n.custom_default_nickname;
    return l10n.home_greeting(userName);
  }

  @override
  void handleBlocStateListener(BuildContext context, HomeState state) {
    super.handleBlocStateListener(context, state);
    if (state.selectedDiaryFeedback != null) {
      bloc.add(const HomeEvent.resetSelectedDiaryFeedback());
      context.push<bool>('/diary/feedback?fromHome=false',
          extra: state.selectedDiaryFeedback);
    }

    if (state.failedDiaryToRetry != null) {
      final targetDiary = state.failedDiaryToRetry!;
      bloc.add(const HomeEvent.clearFailedDiary());

      () async {
        final canWrite = await DiaryUsageHelper.checkCanWriteToday(context,
            isRetryFailed: true);
        if (!canWrite) return;

        if (!context.mounted) return;
        final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
          context: context,
          title: context.l10n.dialog_analysis_retry_title,
          content: context.l10n.dialog_analysis_retry_content,
          elevatedButtonText: context.l10n.action_retry,
          outlineButtonText: context.l10n.action_cancel,
        );

        if (confirmed == true && context.mounted) {
          final payload = DiaryWritePayload(
            date: targetDiary.createdAt.toLocal(),
            topic: '',
            content: targetDiary.content,
            diaryId: targetDiary.id,
          );

          context
              .push<bool>('/diary/processing',
                  extra: jsonEncode(payload.toJson()))
              .then((_) {
            if (context.mounted) {
              bloc.add(const HomeEvent.refreshDiary());
            }
          });
        }
      }();
    }
  }

  @override
  String? get appBarSubtitle {
    final state = bloc.state;
    final totalCount = state.writtenDates.length;
    int consecutiveDays = 0;
    if (state.writtenDates.isNotEmpty) {
      final todayOnly = DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (state.writtenDates.any(
          (date) => DateTime(date.year, date.month, date.day) == todayOnly)) {
        DateTime checkDate = todayOnly;
        while (true) {
          if (state.writtenDates.any((date) =>
              DateTime(date.year, date.month, date.day) == checkDate)) {
            consecutiveDays++;
            checkDate = checkDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }
    }
    if (totalCount == 0) return context.l10n.home_first_diary_prompt;
    if (consecutiveDays > 0) {
      return context.l10n
          .home_total_entries_consecutive(totalCount, consecutiveDays);
    }
    return context.l10n.home_total_entries_count(totalCount);
  }

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async => bloc.add(const HomeEvent.refreshDiary());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _globalBlocSubscription =
        getIt<GlobalBloc>().stream.listen((_) => _tryShowLaunchPromoDialog());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      bloc.add(const HomeEvent.started());
      bloc.add(HomeEvent.loadDiaryForDate(bloc.state.selectedDay, false));
      PermissionRequestHandler.requestNotificationPermission();
      _tryShowLaunchPromoDialog();
    });
  }

  /// 출시 이벤트 팝업 (DB의 홈 화면 온보딩 상태와 연결)
  void _tryShowLaunchPromoDialog() {
    if (!mounted || _launchPromoDialogScheduled) return;

    // 🚨 원인 2 해결: 일기 로딩 중이라고 팝업을 죽이던 isLoading 방해물 삭제!

    final g = getIt<GlobalBloc>().state;
    final u = g.user;
    if (u == null) return;

    // 🚨 원인 1 해결: 로컬 저장소가 아닌 DB의 온보딩 완료 상태(coachMarkHomeDone)를 확인합니다!
    if (g.coachMarkHomeDone) return;

    _launchPromoDialogScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // 화면이 다 그려질 때까지 조금 넉넉히 대기
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;

        final g2 = getIt<GlobalBloc>().state;
        final u2 = g2.user;
        if (u2 == null || g2.coachMarkHomeDone) {
          return;
        }

        final client = SupabaseUtils.getClientOrNull();
        DateTime? endDateFromDb;
        try {
          if (client != null) {
            final subRes = await client
                .from('subscriptions')
                .select('end_date')
                .eq('user_id', u2.id)
                .eq('status', 'active')
                .gte('end_date', DateTime.now().toUtc().toIso8601String())
                .order('end_date', ascending: false)
                .limit(1)
                .maybeSingle();
            if (subRes != null && subRes['end_date'] != null) {
              endDateFromDb =
                  DateTime.parse(subRes['end_date'] as String).toLocal();
            }
          }
        } catch (_) {}

        String endDateStr;
        // 활성 구독(종료일 포함)이 DB에 없어도 팝업을 무조건 띄워주기 위해 기본 텍스트 설정
        if (endDateFromDb == null) {
          endDateStr = '종료일 미정';
        } else {
          endDateStr = DateFormatUtils.formatMonthDay(
            month: endDateFromDb.month,
            day: endDateFromDb.day,
            l10n: context.l10n,
          );
        }

        if (!mounted) return;

        // ✅ 버튼 누르면 깔끔하게 닫히는 다이얼로그 호출!
        await CommonDialogue.showOneChoiceDialogue(
          context: context,
          title: context.l10n.home_launch_promo_after_onboarding_title,
          content:
              context.l10n.home_launch_promo_after_onboarding_body(endDateStr),
          elevatedButtonText: context.l10n.action_confirm,
          barrierDismissible: false,
          blockBackButton: true,
          onElevatedButtonPressed: () {},
        );

        if (mounted) {
          // ✅ 팝업을 확인했으니 드디어 DB의 onboarding_home_done 값을 true로 업데이트!
          getIt<GlobalBloc>()
              .add(const GlobalEvent.patchCoachMarks(homeDone: true));
        }
      } finally {
        _launchPromoDialogScheduled = false;
      }
    });
  }

  @override
  void dispose() {
    _globalBlocSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      bloc.add(const HomeEvent.refreshDiary());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) _isInitialLoad = false;
  }

  @override
  Widget buildPage(BuildContext context, HomeState state) {
    final isFutureDay = _isFutureDate(state.selectedDay);
    final isWithinWritableWeekWindow =
        _isDateWithinWritableWeekWindow(state.selectedDay);
    final remainingHours =
        isFutureDay ? 0 : _remainingHoursForSelectedDate(state.selectedDay);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
                color: Palette.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20))),
            padding: const EdgeInsets.all(16),
            child: HomeCalendarWidget(
              focusedDay: state.selectedDay,
              selectedDay: state.selectedDay,
              today: DateTime.now(),
              writtenDates: state.writtenDates,
              onDaySelected: (date) {
                bloc.add(HomeEvent.dateChanged(date));
                bloc.add(HomeEvent.loadDiaryForDate(date, false));
              },
            ),
          ),
          if (state.isDateSelected) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(
                builder: (context) {
                  final weekdayName = WeekdayUtils.getFullWeekdayNameSync(
                      state.selectedDay.weekday, context.l10n);
                  final hasDiary = state.selectedDateDiary != null;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            Flexible(
                                child: Text(
                                    context.l10n.home_selected_date_format(
                                        state.selectedDay.month,
                                        state.selectedDay.day,
                                        weekdayName),
                                    style: context.h6_700Style,
                                    overflow: TextOverflow.ellipsis)),
                            if (!hasDiary && !isFutureDay) ...[
                              const SizedBox(width: 8),
                              Text('· ${context.l10n.home_not_written}',
                                  style: context.h8_600Style
                                      .copyWith(color: Palette.gray50)),
                            ],
                          ],
                        ),
                      ),
                      if (!hasDiary && !isFutureDay)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!getIt<GlobalBloc>().state.isPremium) ...[
                                Icon(Icons.access_time,
                                    size: 16, color: context.palette.error),
                                const SizedBox(width: 4),
                                Flexible(
                                    child: Text(
                                        remainingHours > 1
                                            ? context.l10n
                                                .home_hours_remaining_about(
                                                    remainingHours)
                                            : remainingHours > 0
                                                ? context
                                                    .l10n.home_deadline_soon
                                                : context
                                                    .l10n.home_deadline_passed,
                                        style: context.h8_400Style.copyWith(
                                            color: context.palette.error),
                                        overflow: TextOverflow.ellipsis)),
                              ]
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (state.selectedDateDiary != null)
            _buildDiaryCard(context, state)
          else if (!isWithinWritableWeekWindow)
            _buildDateRangeNotice(context)
          else
            _buildDiaryWriteButton(context),
        ],
      ),
    );
  }

  Widget _buildDiaryWriteButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CommonElevatedButton(
        text: context.l10n.home_diary_write_button,
        backgroundColor: Palette.black,
        enabledTextColor: Colors.white,
        onPressed: () async {
          final canWrite = await DiaryUsageHelper.checkCanWriteToday(context);
          if (!canWrite) return;

          // 통과된 경우 정상적으로 일기장 진입
          if (!context.mounted) return;
          await DiaryWriteRoute(
            dateMillis: bloc.state.selectedDay.millisecondsSinceEpoch,
            topic: '',
            topicKo: '',
          ).push<bool>(context);
        },
        textStyle: context.h5_700Style.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildDateRangeNotice(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Palette.gray20)),
        child: Center(
            child: Text(context.l10n.home_diary_week_window_notice,
                style: context.h7_400Style.copyWith(color: Palette.gray50),
                textAlign: TextAlign.center)),
      ),
    );
  }

  /// 오늘(로컬) 기준 ±7일(포함) 안에서만 일기 작성 가능
  static const int _writableDayRadius = 7;

  bool _isDateWithinWritableWeekWindow(DateTime date) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final dayOnly = DateTime(date.year, date.month, date.day);
    return dayOnly.difference(today).inDays.abs() <= _writableDayRadius;
  }

  bool _isFutureDate(DateTime date) {
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return DateTime(date.year, date.month, date.day).isAfter(today);
  }

  int _remainingHoursForSelectedDate(DateTime selectedDay) {
    final diff = DateTime(selectedDay.year, selectedDay.month, selectedDay.day)
        .add(const Duration(days: 1))
        .difference(DateTime.now());
    return diff.isNegative ? 0 : (diff.inMinutes / 60).round();
  }

  Widget _buildDiaryCard(BuildContext context, HomeState state) {
    if (state.selectedDateDiary == null) return const SizedBox.shrink();

    final diary = state.selectedDateDiary!;
    final isProcessing = diary.feedbackStatus == 'pending' ||
        diary.feedbackStatus == 'processing' ||
        (diary.feedbackStatus == null &&
            diary.content.isNotEmpty &&
            (diary.correctedContent ?? '').isEmpty);
    final isFailed = diary.feedbackStatus == 'failed';

    return Padding(
        padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
        child: DiaryCard(
          diary: diary,
          onTap: () => bloc.add(const HomeEvent.diaryClicked()),
          isProcessing: isProcessing,
          isFailed: isFailed,
        ));
  }
}
