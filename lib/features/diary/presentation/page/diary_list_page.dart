import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/card/diary_card.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/app/widget/dialogue/diary_usage_helper.dart';
import 'package:kakikaki/app/widget/view/empty_state_widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';
import 'package:kakikaki/features/diary/domain/model/diary_write_payload.dart';
import 'package:kakikaki/features/diary/presentation/bloc/list/diary_list_bloc.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState
    extends BaseScaffoldPageState<DiaryListPage, DiaryListBloc, DiaryListState>
    with WidgetsBindingObserver {
  _DiaryListPageState()
      : super(
          backgroundColor: Palette.gray10,
          horizontalMargin: 0,
          verticalMargin: 0,
        );

  @override
  bool get showDefaultError => true;

  @override
  VoidCallback? get onRetry =>
      () => bloc.add(const DiaryListEvent.loadRequested());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    bloc.add(const DiaryListEvent.started());
    bloc.add(const DiaryListEvent.loadRequested());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      bloc.add(const DiaryListEvent.loadRequested());
    }
  }

  @override
  void handleBlocStateListener(BuildContext context, DiaryListState state) {
    super.handleBlocStateListener(context, state);

    if (state.navigateToFeedbackPayload != null) {
      // push 뒤에 <bool>을 명시하고, .then()으로 돌아왔을 때의 결과를 받음
      context
          .push<bool>(
        '/diary/feedback',
        extra: jsonEncode(state.navigateToFeedbackPayload!.toJson()),
      )
          .then((isModified) {
        // 삭제나 수정이 일어나서 pop(true)로 돌아왔다면 리스트 새로고침
        if (isModified == true && context.mounted) {
          bloc.add(const DiaryListEvent.loadRequested());
        }
      });

      bloc.add(const DiaryListEvent.navigationHandled());
    }
  }

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async =>
      bloc.add(const DiaryListEvent.loadRequested());

  @override
  String get appBarTitle => context.l10n.diary_list_title;

  @override
  Widget buildPage(BuildContext context, DiaryListState state) {
    if (!commonState.isLoading &&
        state.diaries.isEmpty &&
        !commonState.isError) {
      return EmptyStateWidget(
        icon: Icons.edit_note_outlined,
        text: context.l10n.diary_list_empty,
        topPadding: 180,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.diaries.length,
      itemBuilder: (context, index) =>
          _buildDiaryCard(context, state.diaries[index]),
    );
  }

  Widget _buildDiaryCard(BuildContext context, DiaryListItem diary) {
    final localDate = diary.createdAt.toLocal();
    final dateText = context.l10n.diary_list_date_format(
      localDate.year,
      localDate.month,
      localDate.day,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DiaryCard(
        diary: diary,
        date: dateText,
        onTap: () async {
          if (diary.feedbackStatus == 'failed') {
            // 1. 중앙화된 헬퍼에게 작성 가능 여부를 물어봅니다
            final canWrite = await DiaryUsageHelper.checkCanWriteToday(context,
                isRetryFailed: true);
            if (!canWrite) return;

            // 2. 통과했을 때만 팝업 띄우고 진행
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
                date: localDate,
                topic: '',
                content: diary.content,
                diaryId: diary.id,
              );
              context
                  .push<bool>('/diary/processing',
                      extra: jsonEncode(payload.toJson()))
                  .then((_) {
                if (context.mounted) {
                  bloc.add(const DiaryListEvent.loadRequested());
                }
              });
            }
          } else {
            bloc.add(DiaryListEvent.feedbackRequested(diary));
          }
        },
        isProcessing: diary.feedbackStatus == 'pending' ||
            diary.feedbackStatus == 'processing',
        isFailed: diary.feedbackStatus == 'failed',
      ),
    );
  }
}
