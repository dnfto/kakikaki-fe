import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/folder_selection_dialogue.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/domain/model/jlpt_level.dart';
import 'package:kakikaki/core/domain/model/part_of_speech.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/onboarding/tutorial_coach_mark_helper.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/domain/model/vocabulary_entry.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_dialog_helper.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_utils.dart';
import 'package:kakikaki/features/vocabulary/presentation/widget/vocabulary_list_item_card.dart';

class VocabularyListPage extends StatefulWidget {
  const VocabularyListPage({super.key});

  @override
  State<VocabularyListPage> createState() => _VocabularyListPageState();
}

class _VocabularyListPageState extends BaseScaffoldPageState<VocabularyListPage,
    VocabularyListBloc, VocabularyListState> with WidgetsBindingObserver {
  static const int _kOnboardingDummyVocabularyId = -1;

  _VocabularyListPageState()
      : super(
          backgroundColor: Palette.gray10,
          horizontalMargin: 0,
          verticalMargin: 0,
          automaticallyImplyLeading: false,
        );

  final TextEditingController _searchController = TextEditingController();

  final GlobalKey _vocabAppBarCoachKey = GlobalKey();
  StreamSubscription<GlobalState>? _globalBlocSubscription;

  // ✨ 매니저 도입
  final CoachMarkDisplayManager _coachManager = CoachMarkDisplayManager();

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async =>
      bloc.add(const VocabularyListEvent.refresh());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bloc.add(const VocabularyListEvent.initialized());
    _searchController.addListener(_onSearchChanged);
    _globalBlocSubscription = getIt<GlobalBloc>().stream.listen((globalState) {
      if (!mounted) return;
      // 코치마크 완료 상태가 바뀌면 더미 카드 표시 조건이 즉시 반영되도록 리빌드
      setState(() {});
    });
  }

  Future<void> _onVocabCoachFinished() async {
    final gb = getIt<GlobalBloc>();
    if (!gb.state.coachMarkVocabularyDone) {
      gb.add(const GlobalEvent.patchCoachMarks(vocabularyDone: true));
      await gb.stream.firstWhere((s) => s.coachMarkVocabularyDone);
    }
    if (mounted) {
      bloc.add(const VocabularyListEvent.loadFolders(forceRefresh: true));
      bloc.add(const VocabularyListEvent.refresh());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _globalBlocSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      bloc.add(const VocabularyListEvent.refresh());
    }
  }

  void _onSearchChanged() =>
      bloc.add(VocabularyListEvent.searchChanged(_searchController.text));

  @override
  String? get appBarTitle => '나의 단어장';

  @override
  List<Widget>? get rightAppBarActions {
    final state = bloc.state;
    if (state.isSelectionMode) {
      return [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: state.selectedItemIds.isEmpty
              ? null
              : () => _handleUnbookmarkSelected(),
        ),
        IconButton(
          icon: const Icon(Icons.folder_rounded, color: Colors.white),
          onPressed: state.selectedItemIds.isEmpty
              ? null
              : () => _handleFolderChange(),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () =>
              bloc.add(const VocabularyListEvent.toggleSelectionMode()),
        ),
      ];
    }
    return [
      IconButton(
        key: _vocabAppBarCoachKey,
        icon: const Icon(Icons.checklist_rounded, color: Colors.white),
        onPressed: () {
          bloc.add(const VocabularyListEvent.loadFolders());
          bloc.add(const VocabularyListEvent.toggleSelectionMode());
        },
      ),
    ];
  }

  Future<void> _handleUnbookmarkSelected() async {
    final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: context.l10n.vocabulary_delete_title,
      content: context.l10n.vocabulary_delete_content,
      elevatedButtonText: '삭제',
    );
    if (confirmed == true && mounted) {
      bloc.add(const VocabularyListEvent.unbookmarkSelected());
    }
  }

  Future<void> _handleFolderChange() async {
    bloc.add(const VocabularyListEvent.loadFolders(forceRefresh: true));

    while (mounted) {
      final result = await FolderDialogHelper.showWithPremiumCheck(
        context: context,
        folders: bloc.state.folders,
        showToast: (msg) => bloc.addToastMessage(msg),
      );

      if (result == null || !mounted) return;

      if (result == FolderSelectionDialog.createNew) {
        final newFolderName = await CommonDialogue.showInputDialogue(
          maxLength: 50,
          maxLines: 1,
          context: context,
          title: context.l10n.vocabulary_new_folder_title,
          hintText: context.l10n.vocabulary_folder_name_hint,
          outlineButtonText: context.l10n.action_cancel,
          elevatedButtonText: context.l10n.action_create,
        );

        if (!mounted) return;

        // 새 폴더 입력에서 취소/빈값이면 폴더 선택 팝업을 다시 보여줌
        if (newFolderName == null || newFolderName.isEmpty) {
          continue;
        }

        bloc.add(VocabularyListEvent.createFolder(newFolderName));
        return;
      }

      final selectedFolderId =
          result == FolderSelectionDialog.uncategorized ? null : result;
      bloc.add(VocabularyListEvent.moveItemsToFolder(selectedFolderId));
      return;
    }
  }

  @override
  Widget? buildFloatingActionButton(BuildContext context) => null;

  @override
  Widget buildPage(BuildContext context, VocabularyListState state) {
    // ✨ 코치마크 매니저 적용 (300ms 딜레이 포함!)
    _coachManager.showIfNeeded(
      isReady: !commonState.isLoading && !state.isSelectionMode,
      isDone: getIt<GlobalBloc>().state.coachMarkVocabularyDone,
      canShowNow: () =>
          mounted &&
          !state.isSelectionMode &&
          _vocabAppBarCoachKey.currentContext != null &&
          (ModalRoute.of(context)?.isCurrent ?? true),
      showAction: () {
        TutorialCoachMarkHelper.showSingleTarget(
          context: context,
          keyTarget: _vocabAppBarCoachKey,
          description: context.l10n.onboarding_vocabulary_select_mode_body,
          skipLabel: context.l10n.onboarding_skip,
          onComplete: () => unawaited(_onVocabCoachFinished()),
        );
      },
    );

    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildSearchField(context, state)),
        const SizedBox(height: 12),
        Expanded(child: _buildBody(context, state)),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, VocabularyListState state) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
            border: InputBorder.none,
            icon: const Icon(Icons.search, color: Colors.black38),
            hintText: context.l10n.vocabulary_search_hint),
      ),
    );
  }

  VocabularyEntry _onboardingDummyEntry(BuildContext context) {
    final l10n = context.l10n;
    return VocabularyEntry(
      id: _kOnboardingDummyVocabularyId,
      word: l10n.onboarding_vocabulary_dummy_word,
      reading: l10n.onboarding_vocabulary_dummy_reading,
      ruby: null,
      pos: PartOfSpeech.noun,
      meaningTranslated: l10n.onboarding_vocabulary_dummy_meaning,
      exampleJp: '',
      exampleTranslated: '',
      exampleEn: '',
      level: JLPTLevel.n5,
      type: VocabularyType.word,
      studyItemId: null,
      folderId: null,
    );
  }

  Widget _buildBody(BuildContext context, VocabularyListState state) {
    if (commonState.isLoading && state.allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
      return Center(
          child: Text(state.errorMessage!,
              style: context.h6_400Style, textAlign: TextAlign.center));
    }

    final showOnboardingDummy =
        !getIt<GlobalBloc>().state.coachMarkVocabularyDone &&
            state.allItems.isEmpty &&
            !state.isSelectionMode;

    if (showOnboardingDummy) {
      final dummy = _onboardingDummyEntry(context);
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          VocabularyListItemCard(
            item: dummy,
            isSelected: false,
            isSelectionMode: false,
            folderName: context.l10n.folder_uncategorized,
            onTap: () {},
            onLongPress: null,
            onUnbookmarkTapped: () {},
            onCheckTapped: () {},
          ),
        ],
      );
    }

    if (state.filteredItems.isEmpty) {
      return Center(
          child: Text(
              state.allItems.isEmpty
                  ? context.l10n.diary_write_no_words
                  : context.l10n.vocabulary_search_empty,
              style: context.h6_400Style));
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: state.filteredItems.length,
      itemBuilder: (context, index) {
        final item = state.filteredItems[index];
        final isSelected = item.studyItemId != null &&
            state.selectedItemIds.contains(item.studyItemId);

        return VocabularyListItemCard(
          item: item,
          isSelected: isSelected,
          isSelectionMode: state.isSelectionMode,
          folderName: state.folders
              .getFolderName(item.folderId, context.l10n.folder_uncategorized),
          onTap: state.isSelectionMode
              ? () {
                  if (item.studyItemId != null) {
                    bloc.add(VocabularyListEvent.toggleItemSelection(
                        item.studyItemId!));
                  }
                }
              : () async {
                  final result = await context.push<bool>(
                      '/vocabulary/${item.id}?type=${item.type.name}');
                  if (result == true) {
                    bloc.add(const VocabularyListEvent.refresh());
                  }
                },
          onLongPress: state.isSelectionMode
              ? null
              : () {
                  if (item.studyItemId != null) {
                    bloc.add(const VocabularyListEvent.loadFolders());
                    bloc.add(const VocabularyListEvent.toggleSelectionMode());
                    bloc.add(VocabularyListEvent.toggleItemSelection(
                        item.studyItemId!));
                  }
                },
          onUnbookmarkTapped: () => _onUnbookmarkTapped(item),
          onCheckTapped: () {
            if (item.studyItemId != null) {
              bloc.add(
                  VocabularyListEvent.toggleItemSelection(item.studyItemId!));
            }
          },
        );
      },
    );
  }

  Future<void> _onUnbookmarkTapped(VocabularyEntry item) async {
    final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: '단어장에서 삭제',
      content: '이 단어를 단어장에서 삭제하시겠어요?\n학습 기록이 모두 초기화됩니다.',
    );
    if (confirmed == true && mounted) {
      bloc.add(VocabularyListEvent.unbookmark(item));
    }
  }
}
