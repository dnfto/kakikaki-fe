import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';
import 'package:kakikaki/features/diary/domain/repository/diary_repository.dart';
import 'package:kakikaki/features/diary/domain/usecase/get_diary_feedback_usecase.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'home_bloc.freezed.dart';
part 'home_event.dart';
part 'home_state.dart';

@lazySingleton
class HomeBloc extends BaseBloc<HomeEvent, HomeState> {
  HomeBloc(
    this._diaryRepository,
    this._getDiaryFeedbackUseCase,
  ) : super(HomeState.initial(), autoClose: false) {
    onWithoutAutoLoading<HomeStarted>(_onStarted);
    onWithoutAutoLoading<HomeDateChanged>(_onDateChanged);

    // [Guideline 9] on -> onWithoutAutoLoading으로 변경! (화면 전체 딤처리 로딩 방지)
    onWithoutAutoLoading<HomeLoadDiaryForDate>(_onLoadDiaryForDate);
    onWithoutAutoLoading<HomeRefreshDiary>(_onRefreshDiary);

    onWithoutAutoLoading<HomeResetOnLogout>(_onResetOnLogout);
    onWithoutAutoLoading<HomeDiaryClicked>(_onDiaryClicked);
    onWithoutAutoLoading<HomeResetSelectedDiaryFeedback>(
        _onResetSelectedDiaryFeedback);
    onWithoutAutoLoading<HomeClearFailedDiary>(_onClearFailedDiary);
  }

  final DiaryRepository _diaryRepository;
  final GetDiaryFeedbackUseCase _getDiaryFeedbackUseCase;

  static const _writtenDatesCacheDuration = Duration(minutes: 5);
  RealtimeChannel? _homeDiaryChannel;

  @override
  Future<void> close() {
    _homeDiaryChannel?.unsubscribe();
    return super.close();
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    final writtenDates = await _loadWrittenDates(emit);
    emit(state.copyWith(writtenDates: writtenDates));

    // 웹소켓 통신
    final client = SupabaseUtils.getClientOrNull();
    final userId = _resolveUserId();
    if (client != null && userId != null) {
      _homeDiaryChannel?.unsubscribe();
      _homeDiaryChannel = client
          .channel('public:diaries_home')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'diaries',
            filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'user_id',
                value: userId),
            callback: (payload) {
              if (!isClosed) {
                add(const HomeEvent.refreshDiary());
              }
            },
          )
          .subscribe();
    }
  }

  Future<Set<DateTime>> _loadWrittenDates(Emitter<HomeState> emit,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        state.cachedWrittenDates != null &&
        state.writtenDatesCacheTime != null &&
        DateTime.now().difference(state.writtenDatesCacheTime!) <
            _writtenDatesCacheDuration) {
      return state.cachedWrittenDates!;
    }

    final userId = _resolveUserId();
    if (userId == null) return {};

    Set<DateTime> result = {};

    // [Guideline 9] 수동 try-catch를 걷어내고 runBlocCatching 사용!
    await runBlocCatching(
      handleLoading: false,
      handleError: false,
      action: () async =>
          await _diaryRepository.getWrittenDates(userId: userId),
      doOnSuccess: (dates) {
        result = dates;
        emit(state.copyWith(
            cachedWrittenDates: dates, writtenDatesCacheTime: DateTime.now()));
      },
    );

    return result;
  }

  String? _resolveUserId() {
    return getIt<GlobalBloc>().state.user?.id ??
        SupabaseUtils.getClientOrNull()?.auth.currentUser?.id;
  }

  void _onDateChanged(HomeDateChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedDay: event.date, isDateSelected: true));
  }

  Future<void> _onLoadDiaryForDate(
      HomeLoadDiaryForDate event, Emitter<HomeState> emit) async {
    final refreshedWrittenDates = event.forceRefresh
        ? await _loadWrittenDates(emit, forceRefresh: true)
        : null;
    final dateOnly =
        DateTime(event.date.year, event.date.month, event.date.day);

    if (!event.forceRefresh && state.diaryCache.containsKey(dateOnly)) {
      emit(state.copyWith(
          selectedDateDiary: state.diaryCache[dateOnly],
          isLoadingDiary: false,
          writtenDates: refreshedWrittenDates ?? state.writtenDates));
      return;
    }

    final userId = _resolveUserId();
    if (userId == null) {
      emit(state.copyWith(
          selectedDateDiary: null,
          isLoadingDiary: false,
          writtenDates: refreshedWrittenDates ?? state.writtenDates));
      return;
    }

    // [Guideline 9] 수동 try-catch를 걷어내고, doOnEventStart를 활용해 로컬 로딩(isLoadingDiary)만 켬!
    await runBlocCatching(
        handleLoading: false,
        doOnEventStart: () => emit(state.copyWith(isLoadingDiary: true)),
        action: () async => await _diaryRepository.getDiaryByDate(
            userId: userId, date: dateOnly),
        doOnSuccess: (response) {
          final newCache = Map<DateTime, DiaryListItem>.from(state.diaryCache);
          if (response != null) {
            newCache[dateOnly] = response;
          } else {
            newCache.remove(dateOnly);
          }

          emit(state.copyWith(
              selectedDateDiary: response,
              isLoadingDiary: false,
              writtenDates: refreshedWrittenDates ?? state.writtenDates,
              diaryCache: newCache));
        },
        doOnError: (_) {
          emit(state.copyWith(
              selectedDateDiary: null,
              isLoadingDiary: false,
              writtenDates: refreshedWrittenDates ?? state.writtenDates));
        });
  }

  void _onResetOnLogout(HomeResetOnLogout event, Emitter<HomeState> emit) {
    emit(HomeState.initial());
  }

  Future<void> _onDiaryClicked(
      HomeDiaryClicked event, Emitter<HomeState> emit) async {
    final diaryData = state.selectedDateDiary;
    if (diaryData == null || diaryData.id.isEmpty) return;

    if (diaryData.feedbackStatus == 'failed') {
      emit(state.copyWith(failedDiaryToRetry: diaryData));
      return;
    }

    final isProcessing = diaryData.feedbackStatus == 'pending' ||
        diaryData.feedbackStatus == 'processing' ||
        (diaryData.feedbackStatus == null &&
            diaryData.content.isNotEmpty &&
            (diaryData.correctedContent ?? '').isEmpty);

    if (isProcessing) {
      addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
          .home_ai_analyzing_toast);
      return;
    }

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      doOnEventStart: () => emit(state.copyWith(isLoadingFeedback: true)),
      action: () async =>
          await _getDiaryFeedbackUseCase.call(diaryData.toJson()),
      doOnSuccess: (response) {
        if (response.status == FeedbackProcessStatus.processing) {
          addToastMessage(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .home_ai_correcting_toast);
          emit(state.copyWith(isLoadingFeedback: false));
          return;
        }
        if (response.status == FeedbackProcessStatus.failed) {
          addToastMessage(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .home_ai_correct_failed_toast);
        }
        emit(state.copyWith(
            selectedDiaryFeedback: response.result, isLoadingFeedback: false));
      },
      doOnError: (_) => emit(state.copyWith(isLoadingFeedback: false)),
    );
  }

  void _onResetSelectedDiaryFeedback(
      HomeResetSelectedDiaryFeedback event, Emitter<HomeState> emit) {
    emit(state.copyWith(selectedDiaryFeedback: null));
  }

  void _onClearFailedDiary(
      HomeClearFailedDiary event, Emitter<HomeState> emit) {
    emit(state.copyWith(failedDiaryToRetry: null));
  }

  Future<void> _onRefreshDiary(
      HomeRefreshDiary event, Emitter<HomeState> emit) async {
    final writtenDates = await _loadWrittenDates(emit, forceRefresh: true);
    final dateOnly = DateTime(
        state.selectedDay.year, state.selectedDay.month, state.selectedDay.day);

    final newCache = Map<DateTime, DiaryListItem>.from(state.diaryCache);
    newCache.remove(dateOnly);

    final userId = _resolveUserId();
    if (userId == null) {
      emit(state.copyWith(
          selectedDateDiary: null,
          isLoadingDiary: false,
          writtenDates: writtenDates));
      return;
    }

    // 💡 픽스: 현재 일기 상태가 'completed'이거나 'failed'라면 강제로 pending으로 바꾸지 않습니다!
    final currentStatus = state.selectedDateDiary?.feedbackStatus;
    final shouldFakePending =
        currentStatus != 'completed' && currentStatus != 'failed';

    await runBlocCatching(
        handleLoading: false,
        doOnEventStart: () => emit(state.copyWith(
              isLoadingDiary: true,
              diaryCache: newCache,
              // 조건에 맞을 때만 스피너를 위한 가짜 pending 상태를 넣습니다.
              selectedDateDiary: shouldFakePending
                  ? state.selectedDateDiary?.copyWith(feedbackStatus: 'pending')
                  : state.selectedDateDiary,
            )),
        action: () async => await _diaryRepository.getDiaryByDate(
            userId: userId, date: dateOnly),
        doOnSuccess: (diaryItem) {
          if (diaryItem != null) {
            emit(state.copyWith(
                selectedDateDiary: diaryItem,
                isLoadingDiary: false,
                writtenDates: writtenDates,
                diaryCache: {...state.diaryCache, dateOnly: diaryItem}));
          } else {
            emit(state.copyWith(
                selectedDateDiary: null,
                isLoadingDiary: false,
                writtenDates: writtenDates));
          }
        },
        doOnError: (_) {
          emit(state.copyWith(
              selectedDateDiary: null,
              isLoadingDiary: false,
              writtenDates: writtenDates));
        });
  }
}
