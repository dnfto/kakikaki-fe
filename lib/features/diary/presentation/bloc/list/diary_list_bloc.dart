import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';
import 'package:kakikaki/features/diary/domain/usecase/get_diary_feedback_usecase.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'diary_list_bloc.freezed.dart';
part 'diary_list_event.dart';
part 'diary_list_state.dart';

@injectable
class DiaryListBloc extends BaseBloc<DiaryListEvent, DiaryListState> {
  DiaryListBloc(this._getDiaryFeedbackUseCase) : super(const DiaryListState()) {
    onWithoutAutoLoading<DiaryListStarted>(_onStarted);
    on<DiaryListLoadRequested>(_onLoadRequested);
    onWithoutAutoLoading<DiaryListFeedbackRequested>(_onFeedbackRequested);
    onWithoutAutoLoading<DiaryListNavigationHandled>((event, emit) {
      emit(state.copyWith(navigateToFeedbackPayload: null));
    });
  }

  final GetDiaryFeedbackUseCase _getDiaryFeedbackUseCase;
  RealtimeChannel? _diaryListChannel;

  // [Guideline 6] UI에 있던 웹소켓 구독 비즈니스 로직을 BLoC으로 이관!
  Future<void> _onStarted(
      DiaryListStarted event, Emitter<DiaryListState> emit) async {
    final client = SupabaseUtils.getClientOrNull();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    _diaryListChannel?.unsubscribe();
    _diaryListChannel = client
        .channel('public:diaries_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'diaries',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId),
          callback: (payload) {
            if (!isClosed) add(const DiaryListEvent.loadRequested());
          },
        )
        .subscribe();
  }

  @override
  Future<void> close() {
    _diaryListChannel?.unsubscribe();
    return super.close();
  }

  Future<void> _onLoadRequested(
      DiaryListLoadRequested event, Emitter<DiaryListState> emit) async {
    await runBlocCatching(
      handleLoading: true,
      handleError: true,
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        final userId =
            getIt<GlobalBloc>().state.user?.id ?? client?.auth.currentUser?.id;
        if (client == null || userId == null)
          throw Exception(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .login_error);

        final response = await client
            .from('diaries')
            .select(
                'id, content, corrected_content, correction_notes, content_furigana, corrected_content_furigana, created_at, feedback_status')
            .eq('user_id', userId)
            .order('created_at', ascending: false);

        return (response as List)
            .map((json) => DiaryListItem.fromJson(json as Map<String, dynamic>))
            .toList();
      },
      doOnSuccess: (list) => emit(state.copyWith(diaries: list)),
    );
  }

  Future<void> _onFeedbackRequested(
      DiaryListFeedbackRequested event, Emitter<DiaryListState> emit) async {
    final status = event.diary.feedbackStatus;

    if (status == 'pending' || status == 'processing') {
      addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
          .home_ai_correcting_toast);
      return;
    }
    if (status == 'failed')
      addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
          .home_ai_correct_failed_toast);

    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        return await _getDiaryFeedbackUseCase.call(event.diary.toJson());
      },
      doOnSuccess: (response) {
        if (response.status == FeedbackProcessStatus.processing) {
          addToastMessage(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .home_ai_correcting_toast);
          return;
        }
        if (response.status == FeedbackProcessStatus.failed &&
            status != 'failed') {
          addToastMessage(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .home_ai_correct_failed_toast);
        }
        emit(state.copyWith(navigateToFeedbackPayload: response.result));
      },
    );
  }
}
