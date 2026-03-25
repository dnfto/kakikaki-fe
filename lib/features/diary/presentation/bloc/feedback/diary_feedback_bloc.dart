import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';
import 'package:kakikaki/features/diary/domain/repository/bookmark_repository.dart';
import 'package:kakikaki/features/diary/domain/repository/diary_repository.dart';
import 'package:kakikaki/features/home/presentation/bloc/home_bloc.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'diary_feedback_bloc.freezed.dart';
part 'diary_feedback_event.dart';
part 'diary_feedback_state.dart';

@injectable
class DiaryFeedbackBloc
    extends BaseBloc<DiaryFeedbackEvent, DiaryFeedbackState> {
  DiaryFeedbackBloc(this._bookmarkRepository, this._diaryRepository)
      : super(const DiaryFeedbackState()) {
    onWithoutAutoLoading<DiaryFeedbackLoadBookmarksRequested>(
        _onLoadBookmarksRequested);
    onWithoutAutoLoading<DiaryFeedbackBookmarkToggled>(_onBookmarkToggled);
    on<DiaryFeedbackDeleteRequested>(_onDeleteRequested);
    onWithoutAutoLoading<DiaryFeedbackPremiumPopupShown>(
        (event, emit) => emit(state.copyWith(isPremiumLimitReached: false)));
  }

  final BookmarkRepository _bookmarkRepository;
  final DiaryRepository _diaryRepository;
  final Map<String, Set<int>> _bookmarkedIndicesCache = {};

  String? get _userId =>
      getIt<GlobalBloc>().state.user?.id ??
      SupabaseUtils.getClientOrNull()?.auth.currentUser?.id;

  Future<void> _onLoadBookmarksRequested(
      DiaryFeedbackLoadBookmarksRequested event,
      Emitter<DiaryFeedbackState> emit) async {
    final userId = _userId;
    if (userId == null) return;

    final cacheKey = '$userId:${event.diaryId}';
    if (!event.forceRefresh && _bookmarkedIndicesCache.containsKey(cacheKey)) {
      emit(state.copyWith(
          bookmarkedIndices: _bookmarkedIndicesCache[cacheKey]!));
      return;
    }

    await runBlocCatching(
      handleLoading: false,
      action: () async {
        return await _bookmarkRepository.fetchBookmarkedIndices(
          userId: userId,
          diaryId: event.diaryId,
          recommendations: event.recommendations,
        );
      },
      doOnSuccess: (indices) {
        final resultSet = Set<int>.from(indices);
        _bookmarkedIndicesCache[cacheKey] = resultSet;
        emit(state.copyWith(bookmarkedIndices: resultSet));
      },
    );
  }

  Future<void> _onBookmarkToggled(DiaryFeedbackBookmarkToggled event,
      Emitter<DiaryFeedbackState> emit) async {
    final userId = _userId;
    if (userId == null) {
      addToastMessage('로그인 후에 북마크를 사용할 수 있어요.');
      return;
    }

    final isCurrentlyBookmarked = state.bookmarkedIndices.contains(event.index);
    final isPremium = getIt<GlobalBloc>().state.isPremium;

    if (!isCurrentlyBookmarked && !isPremium) {
      final client = SupabaseUtils.getClientOrNull();
      if (client != null) {
        // select() 대신 count()를 사용해 데이터 알맹이는 빼고 '숫자'만 초고속으로 세어서 int 타입으로 바로 반환
        final currentWordCount = await client
            .from('study_items')
            .count(CountOption.exact)
            .eq('user_id', userId);

        if (currentWordCount >= 50) {
          emit(state.copyWith(isPremiumLimitReached: true));
          return;
        }
      }
    }

    final cacheKey = '$userId:${event.diaryId}';

    // 1. 낙관적 UI 업데이트
    final updatedIndices = Set<int>.from(state.bookmarkedIndices);
    isCurrentlyBookmarked
        ? updatedIndices.remove(event.index)
        : updatedIndices.add(event.index);
    emit(state.copyWith(
        bookmarkedIndices: updatedIndices, hasBookmarkChanged: true));

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        await _bookmarkRepository.toggleBookmark(
          item: event.item,
          userId: userId,
          diaryId: event.diaryId,
          currentStatus: isCurrentlyBookmarked,
        );
      },
      doOnSuccess: (_) {
        _bookmarkedIndicesCache[cacheKey] = updatedIndices;
        try {
          getIt<VocabularyListBloc>().add(const VocabularyListEvent.refresh());
        } catch (_) {}
      },
      doOnError: (_) {
        emit(state.copyWith(bookmarkedIndices: state.bookmarkedIndices)); // 롤백
      },
    );
  }

  Future<void> _onDeleteRequested(DiaryFeedbackDeleteRequested event,
      Emitter<DiaryFeedbackState> emit) async {
    final userId = _userId;
    if (userId == null) {
      addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
          .auth_login_required_diary_delete);
      return;
    }

    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        await _diaryRepository.deleteDiary(
            diaryId: event.diaryId, userId: userId);
      },
      doOnSuccess: (_) {
        final targetLocalDate = DateTime(event.date.toLocal().year,
            event.date.toLocal().month, event.date.toLocal().day);
        final homeBloc = getIt<HomeBloc>();
        homeBloc.add(HomeEvent.dateChanged(targetLocalDate));
        homeBloc.add(const HomeEvent.refreshDiary());
        homeBloc.add(HomeEvent.loadDiaryForDate(targetLocalDate, true));

        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .diary_toast_deleted);
        emit(state.copyWith(isDeleted: true));
      },
    );
  }
}
