import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_feedback_result.dart';
import 'package:kakikaki/features/diary/domain/usecase/get_diary_feedback_usecase.dart';
import 'package:kakikaki/features/study/domain/repository/study_repository.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/repository/vocabulary_detail_repository.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

part 'vocabulary_detail_bloc.freezed.dart';
part 'vocabulary_detail_event.dart';
part 'vocabulary_detail_state.dart';

@injectable
class VocabularyDetailBloc
    extends BaseBloc<VocabularyDetailEvent, VocabularyDetailState> {
  VocabularyDetailBloc(
    this._repository,
    this._getDiaryFeedbackUseCase,
    this._vocabularyBloc,
    this._studyRepository,
  ) : super(const VocabularyDetailState()) {
    onWithoutAutoLoading<VocabularyDetailLoaded>(_onDetailLoaded);
    onWithoutAutoLoading<VocabularyDetailDiaryFeedbackRequested>(
        _onDiaryFeedbackRequested);
    onWithoutAutoLoading<VocabularyDetailRealtimeUpdated>(_onRealtimeUpdated);
    onWithoutAutoLoading<VocabularyDetailDiaryFeedbackReset>(
        (e, emit) => emit(state.copyWith(readyDiaryFeedback: null)));
    onWithoutAutoLoading<VocabularyDetailBookmarkChanged>(
        (e, emit) => emit(state.copyWith(hasBookmarkChanged: true)));
    on<VocabularyDetailMoveToFolderRequested>(_onMoveToFolderRequested);
    on<VocabularyDetailUnbookmarkRequested>(_onUnbookmarkRequested);
    onWithoutAutoLoading<VocabularyDetailExcludedPopupShown>(
        (e, emit) => emit(state.copyWith(showExcludedPopup: false)));
  }

  final VocabularyDetailRepository _repository;
  final GetDiaryFeedbackUseCase _getDiaryFeedbackUseCase;
  final VocabularyListBloc _vocabularyBloc;
  final StudyRepository _studyRepository;

  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSubscription;
  Timer? _fallbackTimer;

  void _cleanupRealtimeAndTimer() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _fallbackTimer?.cancel();
    _fallbackTimer = null;
  }

  @override
  Future<void> close() {
    _cleanupRealtimeAndTimer();
    return super.close();
  }

  Future<void> _onDetailLoaded(
      VocabularyDetailLoaded event, Emitter<VocabularyDetailState> emit) async {
    _cleanupRealtimeAndTimer();

    final currentList = _vocabularyBloc.state.filteredItems;
    final currentIndex = currentList.indexWhere(
        (item) => item.id == event.targetId && item.type == event.type);

    if (currentIndex == -1) {
      emit(state.copyWith(
          isLoading: false,
          errorMessage: lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .vocabulary_toast_word_removed));
      return;
    }

    final wordIds = currentList.map((e) => e.id).toList();

    if (event.showLoading) {
      emit(state.copyWith(
          isLoading: true,
          errorMessage: '',
          currentIndex: currentIndex,
          wordIds: wordIds));
    }

    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final userId = getIt<GlobalBloc>().state.user?.id;
        final detail = await _repository.fetchDetailById(event.targetId,
            userId: userId, type: event.type, forceRefresh: !event.showLoading);
        if (detail == null) throw Exception('단어 정보를 찾을 수 없어요.');
        return detail;
      },
      doOnSuccess: (detail) {
        final isSameWord = state.word.isNotEmpty &&
            state.word == detail.word &&
            state.type == detail.type;
        final isExcluded = isSameWord &&
            (state.diaryId != null && state.diaryId!.isNotEmpty) &&
            (detail.diaryId == null || detail.diaryId!.isEmpty);

        emit(state.copyWith(
          targetId: event.targetId,
          word: detail.word,
          reading: detail.reading,
          ruby: detail.ruby,
          pos: detail.pos,
          meaningTranslated: detail.meaningTranslated,
          exampleJp: detail.exampleJp,
          exampleTranslated: detail.exampleTranslated,
          exampleEn: detail.exampleEn,
          level: detail.level,
          diaryId: detail.diaryId,
          type: detail.type,
          studyItemId: detail.studyItemId,
          folderId: detail.folderId,
          isLoading: false,
          errorMessage: '',
          currentIndex: currentIndex,
          wordIds: wordIds,
          isInitialLoad: false,
          isDiaryFetching: false,
          isDiaryProcessing: false,
          showExcludedPopup: isExcluded,
        ));
      },
      doOnError: (e) {
        emit(state.copyWith(
            isLoading: false,
            errorMessage:
                lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                    .vocabulary_toast_load_failed));
      },
    );
  }

  Future<void> _onDiaryFeedbackRequested(
      VocabularyDetailDiaryFeedbackRequested event,
      Emitter<VocabularyDetailState> emit) async {
    final diaryId = state.diaryId;
    if (diaryId == null || diaryId.isEmpty) return;

    if (!state.isDiaryProcessing) {
      emit(state.copyWith(isDiaryFetching: true));
    }

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        final diaryResponse = await _repository.fetchDiaryById(diaryId);
        if (diaryResponse == null) throw Exception('일기 정보를 찾을 수 없어요.');

        return await _getDiaryFeedbackUseCase.call(diaryResponse);
      },
      doOnSuccess: (response) async {
        if (response.status == FeedbackProcessStatus.processing) {
          emit(state.copyWith(isDiaryFetching: false, isDiaryProcessing: true));
          _cleanupRealtimeAndTimer();

          // 1. [웹소켓]
          final client = SupabaseUtils.getClientOrNull();
          if (client != null) {
            _realtimeSubscription = client
                .from('diaries')
                .stream(primaryKey: ['id'])
                .eq('id', diaryId)
                .listen((streamData) {
                  if (streamData.isNotEmpty) {
                    if (!isClosed) {
                      add(VocabularyDetailEvent.realtimeUpdated(
                          streamData.first));
                    }
                  }
                });
          }

          // 2. [타이머]
          int attempts = 0;
          _fallbackTimer =
              Timer.periodic(const Duration(seconds: 3), (timer) async {
            attempts++;
            if (attempts >= 6) {
              _cleanupRealtimeAndTimer();
              if (!isClosed) {
                add(const VocabularyDetailEvent.realtimeUpdated(
                    {'feedback_status': 'timeout'}));
              }
              return;
            }
            try {
              final check = await _repository.fetchDiaryById(diaryId);
              if (check != null) {
                if (!isClosed) {
                  add(VocabularyDetailEvent.realtimeUpdated(check));
                }
              }
            } catch (_) {}
          });

          return;
        }

        if (response.status == FeedbackProcessStatus.failed) {
          addToastMessage(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .home_ai_correct_failed_toast);
        }

        emit(state.copyWith(
          isDiaryFetching: false,
          isDiaryProcessing: false,
          readyDiaryFeedback: response.result,
        ));
      },
      doOnError: (e) {
        _cleanupRealtimeAndTimer();
        emit(state.copyWith(isDiaryFetching: false, isDiaryProcessing: false));
      },
    );
  }

  // [핵심 수정] 백그라운드 감지 이벤트에서 pending/processing 상태도 UI에 반영하도록 수정
  Future<void> _onRealtimeUpdated(VocabularyDetailRealtimeUpdated event,
      Emitter<VocabularyDetailState> emit) async {
    final diaryData = event.diaryData;
    final status = diaryData['feedback_status']?.toString() ?? '';

    // 아직 진행 중이라면 UI만 '처리중'으로 업데이트하고 구독 유지
    if (status == 'pending' || status == 'processing') {
      emit(state.copyWith(isDiaryProcessing: true, isDiaryFetching: false));
      return;
    }

    // 처리가 완료되었거나 실패했다면 구독 취소 및 최종 결과 반영
    if (status == 'completed' || status == 'failed' || status == 'timeout') {
      _cleanupRealtimeAndTimer();
      emit(state.copyWith(isDiaryFetching: false, isDiaryProcessing: false));

      if (status == 'completed' && state.wordIds.isNotEmpty) {
        final list = _vocabularyBloc.state.filteredItems;
        if (state.currentIndex >= 0 && state.currentIndex < list.length) {
          final item = list[state.currentIndex];
          if (!isClosed) {
            add(VocabularyDetailEvent.detailLoaded(item.id,
                type: item.type, showLoading: false));
          }
        }
      }
    }
  }

  Future<void> _onMoveToFolderRequested(
      VocabularyDetailMoveToFolderRequested event,
      Emitter<VocabularyDetailState> emit) async {
    if (state.studyItemId == null) return;

    emit(state.copyWith(folderId: event.folderId));

    getIt<VocabularyListBloc>().add(
        VocabularyListEvent.updateItemFolderOptimistically(
            state.studyItemId!, event.folderId));

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        await _studyRepository.updateStudyItemFolder(
            itemId: state.studyItemId!, folderId: event.folderId);
      },
      doOnSuccess: (_) {
        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .study_toast_folder_changed);
      },
    );
  }

  Future<void> _onUnbookmarkRequested(VocabularyDetailUnbookmarkRequested event,
      Emitter<VocabularyDetailState> emit) async {
    final userId = getIt<GlobalBloc>().state.user?.id;
    final studyItemId = state.studyItemId;
    final targetId = state.targetId;

    if (userId == null || studyItemId == null || targetId == null) return;

    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        if (client == null) {
          throw Exception(
              lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
                  .vocabulary_toast_server_init);
        }

        await client.from('study_items').delete().eq('id', studyItemId);

        final refCol = state.type == 'word' ? 'word_id' : 'grammar_id';
        await client
            .from('user_recommendations')
            .update({'is_bookmarked': false})
            .eq('user_id', userId)
            .eq(refCol, targetId);
      },
      doOnSuccess: (_) {
        _vocabularyBloc.add(const VocabularyListEvent.refresh());
        emit(state.copyWith(hasBookmarkChanged: true));
        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .vocabulary_toast_removed);
      },
    );
  }
}
