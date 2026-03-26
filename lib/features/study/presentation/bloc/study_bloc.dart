import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/domain/model/review_level.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart'; // 필요
import 'package:kakikaki/features/study/domain/model/review_result.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';
import 'package:kakikaki/features/study/domain/repository/study_repository.dart';
import 'package:kakikaki/features/study/domain/usecase/calculate_review_state_usecase.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_event.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_state.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

@lazySingleton
class StudyBloc extends BaseBloc<StudyEvent, StudyState> {
  StudyBloc(
    this._studyRepository,
    this._calculateReviewStateUseCase,
  ) : super(const StudyState(), autoClose: false) {
    onWithoutAutoLoading<StudyInitialized>(_onInitialized);
    on<StudyLoadFolders>(_onLoadFolders);
    on<StudyLoadItems>(_onLoadItems);
    on<StudySelectFolder>(_onSelectFolder);
    onWithoutAutoLoading<StudyGoToFolderSelection>(_onGoToFolderSelection);
    onWithoutAutoLoading<StudyReviewCompleted>(_onReviewCompleted);
    onWithoutAutoLoading<StudyMoveCardToFolder>(_onMoveCardToFolder);
    on<StudyRefresh>(_onRefresh);
    onWithoutAutoLoading<StudyCreateFolder>(_onCreateFolder);
    onWithoutAutoLoading<StudyUpdateFolderName>(_onUpdateFolderName);
    onWithoutAutoLoading<StudyDeleteFolder>(_onDeleteFolder);
    onWithoutAutoLoading<StudyResetOnLogout>(_onResetOnLogout);
    onWithoutAutoLoading<StudyUpdateCardContent>(_onUpdateCardContent);
    onWithoutAutoLoading<StudyLoadExamples>(_onLoadExamples);

    add(const StudyInitialized());
  }

  final StudyRepository _studyRepository;
  final CalculateReviewStateUseCase _calculateReviewStateUseCase;

  GlobalBloc get _globalBloc => getIt<GlobalBloc>();
  GlobalState get _globalState => _globalBloc.state;

  static const _foldersCacheDuration = Duration(minutes: 2);
  static const String _uncategorizedFolderId = '__uncategorized__';

  ReviewResult calculateReviewResult(StudyEntry entry, ReviewLevel level) =>
      _calculateReviewStateUseCase(entry, level);

  Future<void> _onInitialized(
      StudyInitialized event, Emitter<StudyState> emit) async {
    if (state.folders.isNotEmpty) return;
    await runBlocCatching(
        handleLoading: true, action: () async => await _fetchFolders(emit));
  }

  Future<void> _onLoadFolders(
      StudyLoadFolders event, Emitter<StudyState> emit) async {
    await runBlocCatching(
        handleLoading: true, action: () async => await _fetchFolders(emit));
  }

  Future<void> _onLoadItems(
      StudyLoadItems event, Emitter<StudyState> emit) async {
    await runBlocCatching(
      handleLoading: true,
      handleError: true,
      action: () async {
        final userId = _globalBloc.state.user?.id;
        if (userId == null || !_globalBloc.state.isLoggedIn) {
          throw Exception('로그인 후에 학습 기능을 사용할 수 있어요.');
        }
        final items = await _studyRepository.loadStudyItems(
            userId: userId, folderId: event.folderId);

        // [핵심 2] DB에서 가져온 항목들에 원본 루비(Ruby) 데이터를 맵핑해줍니다!
        return await _enhanceItemsWithRuby(items);
      },
      doOnSuccess: (items) => emit(
          state.copyWith(items: items, currentIndex: 0, currentExamples: [])),
    );
  }

  // 실시간으로 원본 사전에서 루비를 합쳐주는 매핑 함수
  Future<List<StudyEntry>> _enhanceItemsWithRuby(List<StudyEntry> items) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null || items.isEmpty) return items;

    final wordTargets = items
        .where((e) => e.type == 'word')
        .map((e) => e.word)
        .toSet()
        .toList();
    final grammarTargets = items
        .where((e) => e.type == 'grammar')
        .map((e) => e.word)
        .toSet()
        .toList();

    // 병렬로 루비 정보 조회
    final results = await Future.wait([
      wordTargets.isNotEmpty
          ? client
              .from('vocabulary')
              .select('word, ruby')
              .inFilter('word', wordTargets)
          : Future.value([]),
      grammarTargets.isNotEmpty
          ? client
              .from('grammar')
              .select('title, ruby')
              .inFilter('title', grammarTargets)
          : Future.value([]),
    ]);

    // O(1) 조회를 위해 Map 변환
    final rubyMap = <String, String>{};
    for (final row in (results[0]).cast<Map<String, dynamic>>()) {
      if (row['ruby'] != null) {
        rubyMap[row['word'].toString()] = row['ruby'].toString();
      }
    }
    for (final row in (results[1]).cast<Map<String, dynamic>>()) {
      if (row['ruby'] != null) {
        rubyMap[row['title'].toString()] = row['ruby'].toString();
      }
    }

    // 기존 리스트에 루비 쏙쏙 주입
    return items
        .map((item) => item.copyWith(ruby: rubyMap[item.word]))
        .toList();
  }

  Future<void> _onSelectFolder(
      StudySelectFolder event, Emitter<StudyState> emit) async {
    emit(state.copyWith(
        selectedFolderId: event.folderId, isFolderSelected: true));
    add(StudyLoadItems(folderId: event.folderId));
  }

  void _onGoToFolderSelection(
      StudyGoToFolderSelection event, Emitter<StudyState> emit) {
    emit(state.copyWith(
        isFolderSelected: false,
        selectedFolderId: null,
        items: [],
        currentIndex: 0,
        currentExamples: []));
  }

  void _onResetOnLogout(StudyResetOnLogout event, Emitter<StudyState> emit) {
    emit(const StudyState());
  }

  // [Guideline 6] 예문 로드 기능
  Future<void> _onLoadExamples(
      StudyLoadExamples event, Emitter<StudyState> emit) async {
    emit(state.copyWith(isLoadingExamples: true));
    try {
      final examples = await _studyRepository.fetchAllExamples(
          word: event.word, type: event.type);
      emit(state.copyWith(currentExamples: examples, isLoadingExamples: false));
    } catch (_) {
      emit(state.copyWith(isLoadingExamples: false));
    }
  }

// [Guideline 2] 복습 버튼 클릭 시 로딩 없이 '즉시' 카드 넘기기 (Optimistic Update)
  Future<void> _onReviewCompleted(
      StudyReviewCompleted event, Emitter<StudyState> emit) async {
    // 1. 화면 즉시 갱신 (로딩 스피너 없음)
    final updatedItems = List<StudyEntry>.from(state.items);
    if (state.currentIndex < updatedItems.length) {
      updatedItems.removeAt(state.currentIndex);
    }

    final now = DateTime.now();
    if (event.result.nextReviewDate.isBefore(now) ||
        event.result.nextReviewDate.isAtSameMomentAs(now)) {
      updatedItems.add(event.entry.applyReview(event.result));
    }

    int newIndex = state.currentIndex;
    if (newIndex >= updatedItems.length) newIndex = 0;

    // 카드 넘어가면 예문 초기화
    emit(state.copyWith(
        items: updatedItems,
        currentIndex: newIndex,
        currentExamples: [],
        isLoadingExamples: false));

    // 2. 백그라운드 DB 통신
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        await _studyRepository.updateReviewState(
          itemId: event.entry.id,
          state: event.result.newState,
          step: event.result.newStep,
          stability: event.result.newStability,
          difficulty: event.result.newDifficulty,
          elapsedDays: event.result.newElapsedDays,
          scheduledDays: event.result.newScheduledDays,
          lapses: event.result.newLapses,
          repetitions: event.result.newRepetitions,
          nextReviewDate: event.result.nextReviewDate,
          lastReviewDate: event.result.lastReviewDate,
        );
      },
    );
  }

  // [Guideline 2] 카드 내용 수정 시 0.1초 즉시 반영
  Future<void> _onUpdateCardContent(
      StudyUpdateCardContent event, Emitter<StudyState> emit) async {
    final idx = state.items.indexWhere((e) => e.id == event.entryId);
    if (idx < 0) return;

    // 1. 즉시 갱신
    final updatedItems = List<StudyEntry>.from(state.items);
    updatedItems[idx] = updatedItems[idx].copyWith(
        meaningTranslated: event.meaningTranslated,
        exampleJp: event.exampleJp,
        exampleTranslated: event.exampleTranslated);
    emit(state.copyWith(items: updatedItems));

    // 2. 조용히 DB 저장
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async => await _studyRepository.updateCardContent(
          itemId: event.entryId,
          meaningTranslated: event.meaningTranslated,
          exampleJp: event.exampleJp,
          exampleTranslated: event.exampleTranslated),
      doOnSuccess: (_) => addToastMessage(
          lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .study_toast_saved),
    );
  }

  // 카드 폴더 이동 즉시 반영
  Future<void> _onMoveCardToFolder(
      StudyMoveCardToFolder event, Emitter<StudyState> emit) async {
    if (!_globalState.isPremium) return;

    final shouldRemove = (state.selectedFolderId == _uncategorizedFolderId &&
            event.folderId != null) ||
        (state.selectedFolderId != null &&
            state.selectedFolderId != _uncategorizedFolderId &&
            event.folderId != state.selectedFolderId);

    // 1. 즉시 화면에서 제거
    if (shouldRemove) {
      final updatedItems = List<StudyEntry>.from(state.items);
      if (state.currentIndex < updatedItems.length)
        updatedItems.removeAt(state.currentIndex);
      int newIndex = state.currentIndex;
      if (newIndex >= updatedItems.length) newIndex = 0;
      emit(state.copyWith(
          items: updatedItems, currentIndex: newIndex, currentExamples: []));
    }

    // 2. 백그라운드 DB 저장
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async => await _studyRepository.updateStudyItemFolder(
          itemId: event.entry.id, folderId: event.folderId),
      doOnSuccess: (_) => addToastMessage(shouldRemove
          ? '폴더가 변경되어 현재 목록에서 제외됐어요.'
          : lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .study_toast_folder_changed),
    );
  }

  Future<void> _onRefresh(StudyRefresh event, Emitter<StudyState> emit) async {
    emit(state.copyWith(premiumStatusCacheTime: null, foldersCacheTime: null));
    await runBlocCatching(
        handleLoading: true,
        action: () async => await _fetchFolders(emit, forceRefresh: true));
    if (state.isFolderSelected)
      add(StudyLoadItems(folderId: state.selectedFolderId));
  }

  Future<void> _fetchFolders(Emitter<StudyState> emit,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        state.foldersCacheTime != null &&
        DateTime.now().difference(state.foldersCacheTime!) <
            _foldersCacheDuration) return;
    final userId = _globalBloc.state.user?.id;
    if (userId == null || !_globalBloc.state.isLoggedIn) return;

    final folders = await _studyRepository.loadFolders(userId: userId);
    emit(state.copyWith(folders: folders, foldersCacheTime: DateTime.now()));
  }

  Future<void> _onCreateFolder(
      StudyCreateFolder event, Emitter<StudyState> emit) async {
    print('[StudyBloc] _onCreateFolder start name="${event.name}"');
    if (!_globalState.isPremium) {
      print('[StudyBloc] _onCreateFolder blocked: not premium');
      return;
    }
    final userId = _globalBloc.state.user?.id;
    if (userId == null || !_globalBloc.state.isLoggedIn) {
      print('[StudyBloc] _onCreateFolder blocked: not logged in');
      return;
    }

    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        print('[StudyBloc] _onCreateFolder creating in repository');
        final newFolder = await _studyRepository.createFolder(
            userId: userId, name: event.name.trim());
        final updatedFolders = List<Folder>.from(state.folders)..add(newFolder);
        print(
          '[StudyBloc] _onCreateFolder success '
          'newFolderId=${newFolder.id}, total=${updatedFolders.length}',
        );
        emit(state.copyWith(folders: updatedFolders));
        try {
          getIt<VocabularyListBloc>()
              .add(VocabularyListEvent.syncFolders(updatedFolders));
        } catch (_) {}
      },
      doOnError: (e) =>
          print('[StudyBloc] _onCreateFolder error: ${e.toString()}'),
      doOnSuccess: (_) => addToastMessage(
          lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .study_toast_folder_created),
    );
  }

  Future<void> _onUpdateFolderName(
      StudyUpdateFolderName event, Emitter<StudyState> emit) async {
    if (!_globalState.isPremium) return;

    final originalFolders = List<Folder>.from(state.folders);
    final optimisticFolders = state.folders
        .map((f) =>
            f.id == event.folderId ? f.copyWith(name: event.name.trim()) : f)
        .toList();
    emit(state.copyWith(folders: optimisticFolders));
    try {
      getIt<VocabularyListBloc>()
          .add(VocabularyListEvent.syncFolders(optimisticFolders));
    } catch (_) {}

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async => await _studyRepository.updateFolderName(
          folderId: event.folderId, name: event.name.trim()),
      doOnSuccess: (_) {
        addToastMessage('폴더 이름이 수정되었어요.');
        if (state.selectedFolderId == event.folderId)
          emit(state.copyWith(selectedFolderId: event.folderId));
      },
      doOnError: (e) {
        emit(state.copyWith(folders: originalFolders));
        try {
          getIt<VocabularyListBloc>()
              .add(VocabularyListEvent.syncFolders(originalFolders));
        } catch (_) {}
      },
    );
  }

  Future<void> _onDeleteFolder(
      StudyDeleteFolder event, Emitter<StudyState> emit) async {
    if (!_globalState.isPremium) return;
    final userId = _globalBloc.state.user?.id;
    if (userId == null || !_globalBloc.state.isLoggedIn) return;

    final originalFolders = List<Folder>.from(state.folders);
    final optimisticFolders =
        state.folders.where((f) => f.id != event.folderId).toList();
    emit(state.copyWith(folders: optimisticFolders));
    try {
      getIt<VocabularyListBloc>()
          .add(VocabularyListEvent.syncFolders(optimisticFolders));
    } catch (_) {}

    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async => await _studyRepository.deleteFolder(
          folderId: event.folderId, userId: userId),
      doOnSuccess: (_) {
        addToastMessage(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
            .study_toast_folder_deleted);
        if (state.selectedFolderId == event.folderId) {
          emit(state.copyWith(
              isFolderSelected: false,
              selectedFolderId: null,
              items: [],
              currentIndex: 0));
        } else if (state.isFolderSelected) {
          add(StudyLoadItems(folderId: state.selectedFolderId));
        }
      },
      doOnError: (e) {
        emit(state.copyWith(folders: originalFolders));
        try {
          getIt<VocabularyListBloc>()
              .add(VocabularyListEvent.syncFolders(originalFolders));
        } catch (_) {}
      },
    );
  }
}
