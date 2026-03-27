import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/button/common_elevated_button.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/folder_selection_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/premium_dialog_hleper.dart';
import 'package:kakikaki/app/widget/overlay/common_tooltip.dart';
import 'package:kakikaki/app/widget/text/kanji_annai.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/app/widget/view/empty_state_widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/onboarding/tutorial_coach_mark_helper.dart';
import 'package:kakikaki/features/study/domain/model/folder.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_bloc.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_event.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_state.dart';
import 'package:kakikaki/features/study/presentation/widgets/review_buttons_widget.dart';
import 'package:kakikaki/features/study/presentation/widgets/study_card_widget.dart';
import 'package:kakikaki/features/study/presentation/widgets/study_folder_selection_section.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_dialog_helper.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_utils.dart';

class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState
    extends BaseScaffoldPageState<StudyPage, StudyBloc, StudyState>
    with SingleTickerProviderStateMixin {
  static const String _uncategorizedFolderId = '__uncategorized__';

  _StudyPageState()
      : super(
            automaticallyImplyLeading: true,
            appBarBackgroundColor: Palette.black);

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  bool _isCardFlipped = false;
  bool _isCreateFolderDialogVisible = false;

  final GlobalKey _uncategorizedFolderCoachKey = GlobalKey();

  // ✨ 매니저 도입
  final CoachMarkDisplayManager _coachManager = CoachMarkDisplayManager();

  final globalBloc = getIt<GlobalBloc>();
  GlobalState get _globalState => globalBloc.state;

  @override
  bool get enablePullToRefresh =>
      bloc.state.isFolderSelected && bloc.state.items.isEmpty;

  @override
  Future<void> onRefresh() async => bloc.add(const StudyEvent.refresh());

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _flipController, curve: Curves.easeInOut));
  }

  Future<void> _onStudyCoachFinished() async {
    if (!globalBloc.state.coachMarkStudyDone) {
      globalBloc.add(const GlobalEvent.patchCoachMarks(studyDone: true));
      await globalBloc.stream.firstWhere((s) => s.coachMarkStudyDone);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  void handleBlocStateListener(BuildContext context, StudyState state) {
    super.handleBlocStateListener(context, state);
    print(
      '[StudyPage] state changed '
      'isFolderSelected=${state.isFolderSelected}, '
      'items=${state.items.length}, '
      'selectedFolderId=${state.selectedFolderId}, '
      'isLoading=${commonState.isLoading}, '
      'isError=${commonState.isError}',
    );
    if (_isCardFlipped && _flipController.isCompleted) {
      _isCardFlipped = false;
      _flipController.reverse();
    }
  }

  void _toggleFlip(StudyEntry entry) {
    safeSetState(() => _isCardFlipped = !_isCardFlipped);
    if (_isCardFlipped) {
      _flipController.forward();
      if (bloc.state.currentExamples.isEmpty) {
        bloc.add(StudyEvent.loadExamples(word: entry.word, type: entry.type));
      }
    } else {
      _flipController.reverse();
    }
  }

  @override
  Widget buildPage(BuildContext context, StudyState state) {
    return PopScope(
      canPop: !state.isFolderSelected,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        print(
          '[StudyPage] onPopInvokedWithResult '
          'didPop=$didPop, result=$result, isFolderSelected=${state.isFolderSelected}',
        );
        if (!didPop) {
          bloc.add(const StudyEvent.goToFolderSelection());
        }
      },
      child: _buildBody(context, state),
    );
  }

  @override
  String get appBarTitle => context.l10n.home_nav_study;

  @override
  Color? get backgroundColor => Palette.gray10;

  @override
  bool get showAppBarLeading =>
      bloc.state.isFolderSelected || Navigator.canPop(context);

  @override
  VoidCallback? get appBarLeadingActionGetter => () {
        if (bloc.state.isFolderSelected) {
          bloc.add(const StudyEvent.goToFolderSelection());
        } else {
          Navigator.maybePop(context);
        }
      };

  Widget _buildBody(BuildContext context, StudyState state) {
    if (!state.isFolderSelected) {
      return _buildFolderSelection(context, state);
    }

    if (state.items.isEmpty) {
      if (commonState.isLoading || commonState.isError) {
        return const SizedBox.shrink();
      }
      return const EmptyStateWidget(
          text: '오늘은 복습할 카드가 없어요.\n일기를 쓰고 단어를 북마크해 보세요!');
    }

    final current = state.items[state.currentIndex];
    final total = state.items.length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.folders.getFolderName(
                      state.selectedFolderId,
                      context.l10n.folder_uncategorized,
                    ),
                    style: context.h3_600Style,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  context.l10n.study_cards_count(state.currentIndex + 1, total),
                  style: context.h8_400Style.copyWith(color: Palette.gray60),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _showEditBottomSheet(context, current),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: context.palette.onSurface,
                  ),
                  label: Text(
                    context.l10n.study_edit_content,
                    style: context.h8_500Style
                        .copyWith(color: context.palette.onSurface),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showMoveToFolderDialog(context, current),
                  icon: Icon(
                    Icons.drive_file_move_outline,
                    size: 18,
                    color: context.palette.onSurface,
                  ),
                  label: Text(
                    context.l10n.study_move,
                    style: context.h8_500Style
                        .copyWith(color: context.palette.onSurface),
                  ),
                ),
              ],
            ),
          ],
        ),
        const KanjiAnnai(),
        const SizedBox(height: 10),
        Center(
          child: StudyCardWidget(
            entry: current,
            flipAnimation: _flipAnimation,
            isFlipped: _isCardFlipped,
            onTap: () => _toggleFlip(current),
            examples: state.currentExamples,
            isLoadingExamples: state.isLoadingExamples,
          ),
        ),
        const SizedBox(height: 10),
        ReviewButtonsWidget(
          entry: current,
          calculateReview: bloc.calculateReviewResult,
          onReview: (level, result) => bloc.add(StudyReviewCompleted(
              entry: current, level: level, result: result)),
        ),
      ],
    );
  }

  Future<void> _showEditBottomSheet(
      BuildContext context, StudyEntry current) async {
    final meaningController =
        TextEditingController(text: current.meaningTranslated);
    final jpController = TextEditingController(text: current.exampleJp);
    final koController = TextEditingController(text: current.exampleTranslated);

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RubyText(
                    text: current.ruby ?? current.word,
                    baseStyle: context.h4_600Style),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context, false)),
              ],
            ),
            const SizedBox(height: 16),
            Text('뜻', style: context.h7_600Style),
            const SizedBox(height: 6),
            TextField(
                controller: meaningController,
                decoration: InputDecoration(
                    hintStyle:
                        context.h8_400Style.copyWith(color: Palette.gray30),
                    filled: true,
                    fillColor: Palette.gray10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
                maxLines: 2),
            const SizedBox(height: 16),
            Row(children: [
              Text('예문', style: context.h7_600Style),
              const SizedBox(width: 4),
              CommonTooltip(message: context.l10n.study_furigana_hint)
            ]),
            const SizedBox(height: 6),
            TextField(
                controller: jpController,
                decoration: InputDecoration(
                    hintText: context.l10n.study_furigana_hint,
                    hintStyle:
                        context.h8_400Style.copyWith(color: Palette.gray30),
                    filled: true,
                    fillColor: Palette.gray10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
                maxLines: 2),
            const SizedBox(height: 16),
            Text(context.l10n.study_example_translation,
                style: context.h7_600Style),
            const SizedBox(height: 6),
            TextField(
                controller: koController,
                decoration: InputDecoration(
                    filled: true,
                    fillColor: Palette.gray10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none)),
                maxLines: 2),
            const SizedBox(height: 24),
            CommonElevatedButton(
              text: context.l10n.study_save,
              height: 52,
              isExpandedWidth: true,
              onPressed: () {
                bloc.add(StudyUpdateCardContent(
                    entryId: current.id,
                    meaningTranslated: meaningController.text.trim(),
                    exampleJp: jpController.text.trim(),
                    exampleTranslated: koController.text.trim()));
                Navigator.pop(context, true);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelection(BuildContext context, StudyState state) {
    // ✨ 매니저 적용
    _coachManager.showIfNeeded(
      isReady: !commonState.isLoading && !_isCreateFolderDialogVisible,
      isDone: getIt<GlobalBloc>().state.coachMarkStudyDone,
      canShowNow: () =>
          mounted &&
          !_isCreateFolderDialogVisible &&
          (ModalRoute.of(context)?.isCurrent ?? true) &&
          _uncategorizedFolderCoachKey.currentContext != null,
      showAction: () {
        print('[StudyPage] show study coach mark');
        TutorialCoachMarkHelper.showSingleTarget(
          context: context,
          keyTarget: _uncategorizedFolderCoachKey,
          description: context.l10n.onboarding_study_uncategorized_body,
          skipLabel: context.l10n.onboarding_skip,
          onComplete: () => unawaited(_onStudyCoachFinished()),
        );
      },
    );

    return StudyFolderSelectionSection(
      folders: state.folders,
      isPremium: _globalState.isPremium,
      uncategorizedFolderKey: _uncategorizedFolderCoachKey,
      onTapUncategorized: () => bloc
          .add(const StudyEvent.selectFolder(folderId: _uncategorizedFolderId)),
      onTapFolder: (folder) =>
          bloc.add(StudyEvent.selectFolder(folderId: folder.id)),
      onCreateFolder: () => _handleCreateFolder(context, state),
      onEditFolder: _globalState.isPremium
          ? (folder) => _showEditFolderDialog(context, folder)
          : null,
      onDeleteFolder: _globalState.isPremium
          ? (folder) => _showDeleteFolderDialog(context, folder)
          : null,
    );
  }

  Future<void> _showMoveToFolderDialog(
      BuildContext context, StudyEntry current) async {
    final result = await FolderDialogHelper.showWithPremiumCheck(
      context: context,
      folders: bloc.state.folders,
      showToast: (msg) => bloc.addToastMessage(msg),
    );

    if (result == null || !context.mounted) return;

    if (result == FolderSelectionDialog.createNew) {
      await _handleCreateFolder(context, bloc.state);
      return;
    }

    final selectedFolderId =
        result == FolderSelectionDialog.uncategorized ? null : result;
    bloc.add(StudyEvent.moveCardToFolder(
        entry: current, folderId: selectedFolderId));
  }

  Future<void> _handleCreateFolder(
      BuildContext context, StudyState state) async {
    if (_isCreateFolderDialogVisible) {
      print('[StudyPage] skip _handleCreateFolder: dialog already visible');
      return;
    }
    if (!_globalState.isPremium) {
      await PremiumDialogHelper.showPremiumGuide(
        context,
        message: context.l10n.study_new_folder_premium,
      );
      return;
    }
    await _showCreateFolderDialog(context);
  }

  Future<void> _showCreateFolderDialog(BuildContext context) async {
    print('[StudyPage] _showCreateFolderDialog open');
    _isCreateFolderDialogVisible = true;
    final routeBefore = ModalRoute.of(context);
    print(
      '[StudyPage] route before dialog '
      'isCurrent=${routeBefore?.isCurrent}, '
      'canPop=${Navigator.of(context).canPop()}, '
      'location=${GoRouter.of(context).state.uri}',
    );
    final result = await CommonDialogue.showInputDialogue(
      maxLength: 50,
      maxLines: 1,
      context: context,
      title: context.l10n.study_new_folder_title,
      hintText: context.l10n.study_folder_name_hint,
      outlineButtonText: context.l10n.action_cancel,
      elevatedButtonText: context.l10n.action_create,
    );
    _isCreateFolderDialogVisible = false;
    final routeAfter = ModalRoute.of(context);
    print(
      '[StudyPage] route after dialog '
      'isCurrent=${routeAfter?.isCurrent}, '
      'canPop=${Navigator.of(context).canPop()}, '
      'location=${GoRouter.of(context).state.uri}',
    );
    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      final delayedRoute = ModalRoute.of(context);
      print(
        '[StudyPage] route delayed(80ms) '
        'isCurrent=${delayedRoute?.isCurrent}, '
        'canPop=${Navigator.of(context).canPop()}, '
        'location=${GoRouter.of(context).state.uri}',
      );
    });
    print(
      '[StudyPage] _showCreateFolderDialog result='
      '${result == null ? 'null' : '"$result"'}',
    );
    if (result != null && result.isNotEmpty) {
      print('[StudyPage] dispatch StudyEvent.createFolder');
      bloc.add(StudyEvent.createFolder(result));
    } else {
      print('[StudyPage] createFolder skipped (empty or cancelled)');
    }
  }

  Future<void> _showEditFolderDialog(
      BuildContext context, Folder folder) async {
    final result = await CommonDialogue.showInputDialogue(
      maxLength: 50,
      maxLines: 1,
      context: context,
      title: context.l10n.study_edit_folder_title,
      hintText: context.l10n.study_folder_name_hint,
      initialValue: folder.name,
      outlineButtonText: context.l10n.action_cancel,
      elevatedButtonText: context.l10n.action_edit,
    );
    if (result != null && result.isNotEmpty && result != folder.name) {
      bloc.add(StudyUpdateFolderName(folderId: folder.id, name: result));
    }
  }

  Future<void> _showDeleteFolderDialog(
      BuildContext context, Folder folder) async {
    final result = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: context.l10n.study_delete_folder_title,
      content: context.l10n.study_delete_folder_message(folder.name),
      outlineButtonText: context.l10n.action_cancel,
      elevatedButtonText: context.l10n.action_delete,
    );
    if (result == true) bloc.add(StudyDeleteFolder(folder.id));
  }
}
