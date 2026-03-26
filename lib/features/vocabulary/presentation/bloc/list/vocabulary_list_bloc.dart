import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/study/domain/repository/study_repository.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_entry.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_bloc.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_event.dart';
import 'package:kakikaki/l10n/app_localizations.dart';

part 'vocabulary_list_bloc.freezed.dart';
part 'vocabulary_list_event.dart';
part 'vocabulary_list_state.dart';

@lazySingleton
class VocabularyListBloc
    extends BaseBloc<VocabularyListEvent, VocabularyListState> {
  StreamSubscription? _globalBlocSubscription;
  String? _currentLanguage;

  VocabularyListBloc(this._studyRepository)
      : super(const VocabularyListState(), autoClose: false) {
    onWithoutAutoLoading<VocabularyInitialized>(_onInitialized);
    on<VocabularyLoadItems>(_onLoadItems);
    onWithoutAutoLoading<VocabularySearchChanged>(_onSearchChanged);
    on<VocabularyRefresh>(_onRefresh);
    on<VocabularyUnbookmark>(_onUnbookmark);
    onWithoutAutoLoading<VocabularyUnbookmarkSelected>(
        _onUnbookmarkSelected); // 로딩바 제거
    onWithoutAutoLoading<VocabularyToggleSelectionMode>(_onToggleSelectionMode);
    onWithoutAutoLoading<VocabularyToggleItemSelection>(_onToggleItemSelection);
    onWithoutAutoLoading<VocabularyToggleAllSelection>(_onToggleAllSelection);
    on<VocabularyLoadFolders>(_onLoadFolders);
    onWithoutAutoLoading<VocabularyMoveItemsToFolder>(
        _onMoveItemsToFolder); // 로딩바 제거
    on<VocabularyCreateFolder>(_onCreateFolder);
    onWithoutAutoLoading<VocabularySyncFolders>(
        (event, emit) => emit(state.copyWith(folders: event.folders)));

    // 상세 화면에서 폴더 바꿨을 때 목록도 0.1초 만에 갱신!
    onWithoutAutoLoading<VocabularyUpdateItemFolderOptimistically>(
        (event, emit) {
      final updatedItems = state.allItems.map((item) {
        if (item.studyItemId == event.studyItemId) {
          return item.copyWith(folderId: event.folderId);
        }
        return item;
      }).toList();
      emit(state.copyWith(allItems: updatedItems));
      _applySearchAndSort(emit);
    });

    onWithoutAutoLoading<VocabularySortTypeChanged>(_onSortTypeChanged);
    onWithoutAutoLoading<VocabularySortOrderChanged>(_onSortOrderChanged);
    onWithoutAutoLoading<VocabularyResetOnLogout>(_onResetOnLogout);
    // 1. 초기 언어 세팅
    _currentLanguage = getIt<GlobalBloc>().state.languageCode;

    // 2. GlobalBloc의 상태 변화를 BLoC 안에서 직접 듣습니다.
    _globalBlocSubscription = getIt<GlobalBloc>().stream.listen((globalState) {
      if (_currentLanguage != globalState.languageCode) {
        _currentLanguage = globalState.languageCode;

        // 언어가 바뀌었고, 이미 불러온 단어 데이터가 있다면 스스로 새로고침(refresh)을 트리거합니다.
        if (state.allItems.isNotEmpty) {
          add(const VocabularyListEvent.refresh());
        }
      }
    });
  }

  // 3. BLoC이 종료될 때 구독 해제 (메모리 누수 방지)
  @override
  Future<void> close() {
    _globalBlocSubscription?.cancel();
    return super.close();
  }

  final StudyRepository _studyRepository;
  List<Folder>? _cachedFolders;
  DateTime? _foldersCacheTime;
  static const _foldersCacheDuration = Duration(minutes: 2);

  String? get _userId =>
      getIt<GlobalBloc>().state.user?.id ??
      SupabaseUtils.getClientOrNull()?.auth.currentUser?.id;

  Future<void> _onInitialized(
      VocabularyInitialized event, Emitter<VocabularyListState> emit) async {
    if (state.allItems.isNotEmpty) {
      _applySearchAndSort(emit);
      return;
    }

    // 코치마크 미완료 상태에서는 더미 카드/코치마크를 먼저 보여주고
    // 코치마크 완료 후에 실제 데이터를 로드한다.
    if (!getIt<GlobalBloc>().state.coachMarkVocabularyDone) {
      return;
    }

    await runBlocCatching(
        handleLoading: true,
        action: () async {
          await _fetchFolders(emit);
          await _fetchItems(emit);
        });
  }

  Future<void> _onLoadItems(
      VocabularyLoadItems event, Emitter<VocabularyListState> emit) async {
    await runBlocCatching(
        handleLoading: true, action: () async => await _fetchItems(emit));
  }

  void _onSearchChanged(
      VocabularySearchChanged event, Emitter<VocabularyListState> emit) {
    emit(state.copyWith(searchQuery: event.query));
    _applySearchAndSort(emit);
  }

  Future<void> _onRefresh(
      VocabularyRefresh event, Emitter<VocabularyListState> emit) async {
    await runBlocCatching(
        handleLoading: true, action: () async => await _fetchItems(emit));
  }

  Future<void> _onUnbookmark(
      VocabularyUnbookmark event, Emitter<VocabularyListState> emit) async {
    final userId = _userId;
    if (userId == null) return;
    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        final client = SupabaseUtils.getClientOrNull()!;
        var query = client
            .from('user_recommendations')
            .select('id')
            .eq('user_id', userId)
            .eq('item_type', event.item.type.name);
        query = event.item.type == VocabularyType.word
            ? query.eq('word_id', event.item.id)
            : query.eq('grammar_id', event.item.id);
        final existingRec = await query.limit(1).maybeSingle();
        if (existingRec != null) {
          await client
              .from('user_recommendations')
              .update({'is_bookmarked': false}).eq('id', existingRec['id']);
          await client
              .from('study_items')
              .delete()
              .eq('user_id', userId)
              .eq('type', event.item.type.name)
              .eq('word', event.item.word);
        }
      },
      doOnSuccess: (_) async {
        addToastMessage('단어장에서 삭제되었어요.');
        await _fetchItems(emit);
      },
    );
  }

  // ====================================================================
  // 일괄 삭제 최적화 (for-await 제거, 화면 즉시 반영)
  // ====================================================================
  Future<void> _onUnbookmarkSelected(VocabularyUnbookmarkSelected event,
      Emitter<VocabularyListState> emit) async {
    final userId = _userId;
    if (userId == null || state.selectedItemIds.isEmpty) return;

    // 1. 낙관적 업데이트: 화면에서 즉시 단어 증발시킴! (로딩바 X)
    final targetStudyItemIds = List<String>.from(state.selectedItemIds);
    final remainingItems = state.allItems
        .where((item) => !targetStudyItemIds.contains(item.studyItemId))
        .toList();

    final wordIds = <int>[];
    final grammarIds = <int>[];
    for (final item in state.allItems
        .where((i) => targetStudyItemIds.contains(i.studyItemId))) {
      if (item.type == VocabularyType.word) {
        wordIds.add(item.id);
      } else {
        grammarIds.add(item.id);
      }
    }

    emit(state.copyWith(
        allItems: remainingItems, isSelectionMode: false, selectedItemIds: {}));
    _applySearchAndSort(emit);

    // 2. 백그라운드 DB 삭제 (inFilter 병렬 처리)
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        final client = SupabaseUtils.getClientOrNull()!;
        final futures = <Future>[];
        if (wordIds.isNotEmpty) {
          futures.add(client
              .from('user_recommendations')
              .update({'is_bookmarked': false})
              .eq('user_id', userId)
              .eq('item_type', 'word')
              .inFilter('word_id', wordIds));
        }
        if (grammarIds.isNotEmpty) {
          futures.add(client
              .from('user_recommendations')
              .update({'is_bookmarked': false})
              .eq('user_id', userId)
              .eq('item_type', 'grammar')
              .inFilter('grammar_id', grammarIds));
        }
        if (targetStudyItemIds.isNotEmpty) {
          futures.add(client
              .from('study_items')
              .delete()
              .inFilter('id', targetStudyItemIds));
        }

        await Future.wait(futures);
      },
      doOnSuccess: (_) => addToastMessage(
          lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .vocabulary_toast_deleted),
    );
  }

  void _onToggleSelectionMode(
      VocabularyToggleSelectionMode event, Emitter<VocabularyListState> emit) {
    emit(state.copyWith(
        isSelectionMode: !state.isSelectionMode,
        selectedItemIds: state.isSelectionMode ? {} : state.selectedItemIds));
  }

  void _onToggleItemSelection(
      VocabularyToggleItemSelection event, Emitter<VocabularyListState> emit) {
    final newSelectedIds = Set<String>.from(state.selectedItemIds);
    if (newSelectedIds.contains(event.studyItemId)) {
      newSelectedIds.remove(event.studyItemId);
    } else {
      newSelectedIds.add(event.studyItemId);
    }
    emit(state.copyWith(selectedItemIds: newSelectedIds));
  }

  void _onToggleAllSelection(
      VocabularyToggleAllSelection event, Emitter<VocabularyListState> emit) {
    if (state.selectedItemIds.length == state.filteredItems.length) {
      emit(state.copyWith(selectedItemIds: {}));
    } else {
      emit(state.copyWith(
          selectedItemIds: state.filteredItems
              .where((item) => item.studyItemId != null)
              .map((item) => item.studyItemId!)
              .toSet()));
    }
  }

  Future<void> _onLoadFolders(
      VocabularyLoadFolders event, Emitter<VocabularyListState> emit) async {
    await runBlocCatching(
        handleLoading: true,
        action: () async =>
            await _fetchFolders(emit, forceRefresh: event.forceRefresh));
  }

  // ====================================================================
  // 폴더 일괄 이동 최적화 (화면 즉시 반영)
  // ====================================================================
  Future<void> _onMoveItemsToFolder(VocabularyMoveItemsToFolder event,
      Emitter<VocabularyListState> emit) async {
    if (state.selectedItemIds.isEmpty) return;

    // 1. 낙관적 업데이트: 화면의 칩(Chip) 즉시 변경
    final targetIds = List<String>.from(state.selectedItemIds);
    final updatedItems = state.allItems.map((item) {
      if (targetIds.contains(item.studyItemId)) {
        return item.copyWith(folderId: event.folderId);
      }
      return item;
    }).toList();

    emit(state.copyWith(
        allItems: updatedItems, isSelectionMode: false, selectedItemIds: {}));
    _applySearchAndSort(emit);

    // 2. 백그라운드 DB 변경
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      action: () async {
        final futures = targetIds.map((id) => _studyRepository
            .updateStudyItemFolder(itemId: id, folderId: event.folderId));
        await Future.wait(futures);
      },
      doOnSuccess: (_) => addToastMessage('선택한 항목들의 폴더가 변경되었어요.'),
    );
  }

  Future<void> _onCreateFolder(
      VocabularyCreateFolder event, Emitter<VocabularyListState> emit) async {
    if (!getIt<GlobalBloc>().state.isPremium) {
      return;
    }
    final userId = _userId;
    if (userId == null) return;
    await runBlocCatching(
      handleLoading: true,
      handleToast: true,
      action: () async {
        final newFolder = await _studyRepository.createFolder(
            userId: userId, name: event.name.trim());
        final updatedFolders = List<Folder>.from(state.folders)..add(newFolder);
        emit(state.copyWith(folders: updatedFolders));
        try {
          getIt<StudyBloc>().add(const StudyRefresh());
        } catch (_) {}
        if (state.isSelectionMode && state.selectedItemIds.isNotEmpty) {
          add(VocabularyListEvent.moveItemsToFolder(newFolder.id));
        }
      },
      doOnSuccess: (_) => addToastMessage(
          lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
              .vocabulary_toast_folder_created),
    );
  }

  void _onSortTypeChanged(
      VocabularySortTypeChanged event, Emitter<VocabularyListState> emit) {
    emit(state.copyWith(sortType: event.sortType));
    _applySearchAndSort(emit);
  }

  void _onSortOrderChanged(
      VocabularySortOrderChanged event, Emitter<VocabularyListState> emit) {
    emit(state.copyWith(sortOrder: event.sortOrder));
    _applySearchAndSort(emit);
  }

  void _onResetOnLogout(
      VocabularyResetOnLogout event, Emitter<VocabularyListState> emit) {
    emit(const VocabularyListState());
  }

  Future<void> _fetchItems(Emitter<VocabularyListState> emit) async {
    final client = SupabaseUtils.getClientOrNull();
    final userId = _userId;

    if (client == null || userId == null) {
      throw Exception(lookupAppLocalizations(getIt<GlobalBloc>().state.locale)
          .vocabulary_toast_load_error);
    }

    final userRecResponse = await client
        .from('user_recommendations')
        .select('word_id, grammar_id, created_at')
        .eq('user_id', userId)
        .eq('is_bookmarked', true)
        .order('created_at', ascending: false);

    final wordIds = <int>[];
    final grammarIds = <int>[];

    for (final rec in userRecResponse as List) {
      final w = rec['word_id'];
      final g = rec['grammar_id'];

      if (w != null) wordIds.add(w as int);
      if (g != null) grammarIds.add(g as int);
    }

    // ----------------------------------------
    // DB 요청 병렬 처리
    // ----------------------------------------

    final futures = await Future.wait([
      wordIds.isNotEmpty
          ? client
              .from('vocabulary')
              .select('id, word, reading, ruby, pos, meanings, examples, level')
              .inFilter('id', wordIds)
          : Future.value([]),
      grammarIds.isNotEmpty
          ? client
              .from('grammar')
              .select('id, title, reading, ruby, level, meaning, examples')
              .inFilter('id', grammarIds)
          : Future.value([]),
    ]);

    final vocabItems = futures[0];
    final grammarItems = futures[1];

    // ----------------------------------------
    // study_items 조회 병렬화
    // ----------------------------------------

    final vocabWords =
        vocabItems.map((item) => item['word'] as String).toList();

    final grammarTitles =
        grammarItems.map((item) => item['title'] as String).toList();

    final studyFutures = await Future.wait([
      vocabWords.isNotEmpty
          ? client
              .from('study_items')
              .select('id, folder_id, word')
              .eq('user_id', userId)
              .eq('type', 'word')
              .inFilter('word', vocabWords)
          : Future.value([]),
      grammarTitles.isNotEmpty
          ? client
              .from('study_items')
              .select('id, folder_id, word')
              .eq('user_id', userId)
              .eq('type', 'grammar')
              .inFilter('word', grammarTitles)
          : Future.value([]),
    ]);

    final vocabStudyItems = studyFutures[0];
    final grammarStudyItems = studyFutures[1];

    // ----------------------------------------
    // Map 생성 최적화
    // ----------------------------------------

    final vocabStudyMap = {
      for (final item in vocabStudyItems)
        item['word']: {
          'id': item['id']?.toString(),
          'folder_id': item['folder_id']?.toString(),
        }
    };

    final grammarStudyMap = {
      for (final item in grammarStudyItems)
        item['word']: {
          'id': item['id']?.toString(),
          'folder_id': item['folder_id']?.toString(),
        }
    };

    // ----------------------------------------
    // VocabularyEntry 생성
    // ----------------------------------------

    final vocabList = vocabItems.map<VocabularyEntry>((item) {
      final word = item['word'] as String?;
      final studyItem = word != null ? vocabStudyMap[word] : null;

      return VocabularyEntry.fromVocabJson({
        ...item,
        'study_item_id': studyItem?['id'],
        'folder_id': studyItem?['folder_id']
      }, 'word');
    }).toList();

    final grammarList = grammarItems.map<VocabularyEntry>((item) {
      final title = item['title'] as String?;
      final studyItem = title != null ? grammarStudyMap[title] : null;

      return VocabularyEntry.fromGrammarJson({
        ...item,
        'study_item_id': studyItem?['id'],
        'folder_id': studyItem?['folder_id']
      }, 'grammar');
    }).toList();

    final allItems = [...vocabList, ...grammarList];

    emit(state.copyWith(allItems: allItems));
    _applySearchAndSort(emit);
  }

  Future<void> _fetchFolders(Emitter<VocabularyListState> emit,
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _cachedFolders != null &&
        _foldersCacheTime != null &&
        DateTime.now().difference(_foldersCacheTime!) < _foldersCacheDuration) {
      emit(state.copyWith(folders: _cachedFolders!));
      return;
    }
    final userId = _userId;
    if (userId == null) return;
    final folders = await _studyRepository.loadFolders(userId: userId);
    _cachedFolders = folders;
    _foldersCacheTime = DateTime.now();
    emit(state.copyWith(folders: folders));
  }

  void _applySearchAndSort(Emitter<VocabularyListState> emit) {
    final query = state.searchQuery.trim().toLowerCase();
    List<VocabularyEntry> filtered = query.isEmpty
        ? List.from(state.allItems)
        : state.allItems.where((item) => _matchesQuery(item, query)).toList();
    filtered = _applySort(filtered, state.sortType, state.sortOrder);
    emit(state.copyWith(filteredItems: filtered));
  }

  String _normalizeRuby(String input) {
    if (input.isEmpty) return input;
    return input.replaceAll(RegExp(r'[\[\]\(\)]'), '');
  }

  bool _matchesQuery(VocabularyEntry item, String query) {
    final word = item.word.toLowerCase();
    final meaning = item.meaningTranslated.toLowerCase();
    final reading = item.reading.toLowerCase();
    final normalizedReading = _normalizeRuby(reading);
    return word.contains(query) ||
        meaning.contains(query) ||
        reading.contains(query) ||
        normalizedReading.contains(query);
  }

  List<VocabularyEntry> _applySort(List<VocabularyEntry> items,
      VocabularySortType sortType, VocabularySortOrder sortOrder) {
    var sorted = List<VocabularyEntry>.from(items);
    switch (sortType) {
      case VocabularySortType.word:
        sorted.sort((a, b) {
          final comparison = a.word.compareTo(b.word);
          return sortOrder == VocabularySortOrder.ascending
              ? comparison
              : -comparison;
        });
        break;
      case VocabularySortType.date:
        if (sortOrder == VocabularySortOrder.ascending) {
          sorted = sorted.reversed.toList();
        }
        break;
      case VocabularySortType.level:
        sorted.sort((a, b) {
          final levelOrder = {
            'N1': 1,
            'N2': 2,
            'N3': 3,
            'N4': 4,
            'N5': 5,
            'ETC': 6
          };
          final aOrder = levelOrder[a.level.nameString] ?? 6;
          final bOrder = levelOrder[b.level.nameString] ?? 6;
          final comparison = aOrder.compareTo(bOrder);
          return sortOrder == VocabularySortOrder.ascending
              ? comparison
              : -comparison;
        });
        break;
      case VocabularySortType.type:
        sorted.sort((a, b) {
          final aOrder = a.type == VocabularyType.word ? 1 : 2;
          final bOrder = b.type == VocabularyType.word ? 1 : 2;
          final comparison = aOrder.compareTo(bOrder);
          return sortOrder == VocabularySortOrder.ascending
              ? comparison
              : -comparison;
        });
        break;
    }
    return sorted;
  }
}
