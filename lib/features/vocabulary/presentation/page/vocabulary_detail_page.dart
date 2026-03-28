import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/dialogue/folder_selection_dialogue.dart';
import 'package:kakikaki/app/widget/text/kanji_annai.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/vocabulary/domain/enum/vocabulary_type.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/detail/vocabulary_detail_bloc.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_dialog_helper.dart';
import 'package:kakikaki/features/vocabulary/presentation/utils/folder_utils.dart';

class VocabularyDetailPage extends StatefulWidget {
  const VocabularyDetailPage({super.key, required this.id, required this.type});

  final int id;
  final VocabularyType type;

  @override
  State<VocabularyDetailPage> createState() => _VocabularyDetailPageState();
}

class _VocabularyDetailPageState extends BaseScaffoldPageState<
    VocabularyDetailPage, VocabularyDetailBloc, VocabularyDetailState> {
  _VocabularyDetailPageState() : super(horizontalMargin: 0, verticalMargin: 0);

  final globalBloc = getIt<GlobalBloc>();

  @override
  void initState() {
    super.initState();
    bloc.add(VocabularyDetailEvent.detailLoaded(widget.id,
        type: widget.type, showLoading: true));
  }

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async {
    if (bloc.state.wordIds.isEmpty) return;
    final vocabularyBloc = getIt<VocabularyListBloc>();
    final list = vocabularyBloc.state.filteredItems;
    final idx = bloc.state.currentIndex;
    if (idx < 0 || idx >= list.length) return;
    final item = list[idx];
    bloc.add(VocabularyDetailEvent.detailLoaded(item.id,
        type: item.type, showLoading: false));
  }

  @override
  void handleBlocStateListener(
      BuildContext context, VocabularyDetailState state) {
    super.handleBlocStateListener(context, state);

    // 삭제가 완료되었으면 목록 화면으로 돌아갑니다.
    if (state.hasBookmarkChanged && !commonState.isLoading) {
      if (context.mounted && Navigator.canPop(context)) {
        context.pop(true); // true를 넘겨서 이전 화면(단어장 목록)이 새로고침되게 합니다.
      }
      return; // pop을 했으므로 아래 로직은 타지 않게 방어
    }

    if (state.showExcludedPopup) {
      bloc.add(const VocabularyDetailEvent.excludedPopupShown());
      CommonDialogue.showOneChoiceDialogue(
        context: context,
        title: '추천 제외',
        content: '수정된 일기에서는 이 표현이\n추천 목록에서 제외되었어요.\n단어장에는 계속 보관되니 안심하세요!',
        elevatedButtonText: '확인',
        onElevatedButtonPressed: () {},
      );
    }

    if (state.readyDiaryFeedback != null) {
      final feedback = state.readyDiaryFeedback!;
      final vocabularyBloc = getIt<VocabularyListBloc>();
      final list = vocabularyBloc.state.filteredItems;
      final idx = state.currentIndex;

      // currentId와 currentType을 안전하게 가져오기
      final currentId = (idx >= 0 && idx < list.length) ? list[idx].id : null;
      final VocabularyType? currentType =
          (idx >= 0 && idx < list.length) ? list[idx].type : null;

      bloc.add(const VocabularyDetailEvent.diaryFeedbackReset());

      context.push<bool>('/diary/feedback', extra: feedback).then((result) {
        // 여기서 currentType이 null이 아님을 확인 후 이벤트 전송
        if (result == true &&
            context.mounted &&
            currentId != null &&
            currentType != null) {
          bloc.add(const VocabularyDetailEvent.bookmarkChanged());
          bloc.add(VocabularyDetailEvent.detailLoaded(
            currentId,
            type: currentType, // 이제 Enum 타입임
            showLoading: false,
          ));
        }
      });
    }
  }

  @override
  String get appBarTitle => '단어 상세';

  @override
  List<Widget>? get rightAppBarActions {
    return [
      // 삭제(휴지통) 버튼 추가
      IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.white),
        onPressed:
            bloc.state.studyItemId != null ? () => _handleUnbookmark() : null,
        tooltip: context.l10n.vocabulary_tooltip_delete,
      ),
      IconButton(
        icon: const Icon(Icons.folder_rounded, color: Colors.white),
        onPressed:
            bloc.state.studyItemId != null ? () => _handleFolderChange() : null,
        tooltip: context.l10n.vocabulary_tooltip_change_folder,
      ),
    ];
  }

  // 삭제 확인 팝업 및 이벤트 전송
  Future<void> _handleUnbookmark() async {
    final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: context.l10n.vocabulary_delete_title,
      content: context.l10n.vocabulary_delete_content,
      elevatedButtonText: context.l10n.action_delete,
    );
    if (confirmed == true && mounted) {
      bloc.add(const VocabularyDetailEvent.unbookmarkRequested());
    }
  }

  Future<void> _handleFolderChange() async {
    final vocabularyBloc = getIt<VocabularyListBloc>();
    vocabularyBloc
        .add(const VocabularyListEvent.loadFolders(forceRefresh: true));

    final result = await FolderDialogHelper.showWithPremiumCheck(
      context: context,
      folders: vocabularyBloc.state.folders,
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
      if (newFolderName != null && newFolderName.isNotEmpty) {
        vocabularyBloc.add(VocabularyListEvent.createFolder(newFolderName));
      }
      return;
    }

    final selectedFolderId =
        result == FolderSelectionDialog.uncategorized ? null : result;
    bloc.add(VocabularyDetailEvent.moveToFolderRequested(selectedFolderId));
  }

  @override
  Widget buildPage(BuildContext context, VocabularyDetailState state) {
    return _buildBody(context, state);
  }

  Widget _buildBody(BuildContext context, VocabularyDetailState state) {
    if (state.isLoading && state.isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage.isNotEmpty) {
      return Center(
          child: Text(state.errorMessage,
              style: context.h6_400Style, textAlign: TextAlign.center));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final vocabularyBloc = getIt<VocabularyListBloc>();
                            return CommonChip(
                              label: vocabularyBloc.state.folders.getFolderName(
                                  state.folderId,
                                  context.l10n.folder_uncategorized),
                              icon: Icons.folder_rounded,
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        CommonChip(
                            label: state.type == 'grammar'
                                ? context.l10n.diary_feedback_chip_grammar
                                : context
                                    .l10n.vocabulary_detail_vocabulary_label),
                        const SizedBox(width: 6),
                        if (state.level != null)
                          CommonChip(label: state.level!.nameString),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final vocabularyBloc = getIt<VocabularyListBloc>();
                        final list = vocabularyBloc.state.filteredItems;
                        final hasPrevious = state.currentIndex > 0;
                        final hasNext = state.currentIndex < list.length - 1;
                        final prevItem =
                            hasPrevious ? list[state.currentIndex - 1] : null;
                        final nextItem =
                            hasNext ? list[state.currentIndex + 1] : null;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CommonIconButton(
                              icon: const Icon(Icons.chevron_left, size: 32),
                              primary: hasPrevious
                                  ? context.palette.primary
                                  : Palette.gray30,
                              onPressed: prevItem != null
                                  ? () => bloc.add(
                                      VocabularyDetailEvent.detailLoaded(
                                          prevItem.id,
                                          type: prevItem.type,
                                          showLoading: false))
                                  : null,
                            ),
                            Expanded(
                              child: Center(
                                child: (state.ruby != null &&
                                        state.ruby!.isNotEmpty)
                                    ? RubyText(
                                        text: state.ruby!,
                                        baseStyle: context.h2_700Style)
                                    : RubyText(
                                        text: state.word,
                                        baseStyle: context.h2_700Style),
                              ),
                            ),
                            CommonIconButton(
                              icon: const Icon(Icons.chevron_right, size: 32),
                              primary: hasNext
                                  ? context.palette.primary
                                  : Palette.gray30,
                              onPressed: nextItem != null
                                  ? () => bloc.add(
                                      VocabularyDetailEvent.detailLoaded(
                                          nextItem.id,
                                          type: nextItem.type,
                                          showLoading: false))
                                  : null,
                            ),
                          ],
                        );
                      },
                    ),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const KanjiAnnai()),
                    if (state.meaningTranslated.isNotEmpty) ...[
                      Text(context.l10n.study_label_meaning,
                          style: context.h5_600Style),
                      const SizedBox(height: 4),
                      RubyText(
                          text: state.meaningTranslated,
                          baseStyle: context.h6_400Style
                              .copyWith(color: Palette.gray70)),
                      const SizedBox(height: 20),
                    ],
                    if (state.exampleJp.isNotEmpty ||
                        state.exampleTranslated.isNotEmpty ||
                        state.exampleEn.isNotEmpty) ...[
                      Text(context.l10n.study_label_example,
                          style: context.h5_600Style),
                      const SizedBox(height: 8),
                      if (state.exampleJp.isNotEmpty)
                        RubyText(
                            text: state.exampleJp,
                            baseStyle: context.h6_400Style
                                .copyWith(color: Palette.gray70)),
                      if (state.exampleTranslated.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(state.exampleTranslated,
                            style: context.h6_400Style
                                .copyWith(color: Palette.gray60))
                      ],
                      if (state.exampleEn.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(state.exampleEn,
                            style: context.h6_400Style
                                .copyWith(color: Palette.gray50))
                      ],
                    ],
                    if (state.diaryId != null && state.diaryId!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      CommonElevatedButton(
                        text: state.isDiaryProcessing
                            ? 'AI가 수정된 일기를 교정중...'
                            : '그날의 일기 보기',
                        isLoading:
                            state.isDiaryFetching || state.isDiaryProcessing,
                        backgroundColor: Palette.black,
                        enabledTextColor: Palette.white,
                        onPressed:
                            (state.isDiaryFetching || state.isDiaryProcessing)
                                ? null
                                : () => bloc.add(const VocabularyDetailEvent
                                    .diaryFeedbackRequested()),
                      ),
                    ],
                  ],
                ),
                Center(
                  child: Text(
                      '${state.currentIndex + 1} / ${state.wordIds.length}',
                      style:
                          context.h7_400Style.copyWith(color: Palette.gray50)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
