import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/formatter_utils.dart';
import 'package:kakikaki/core/utils/weekday_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_write_payload.dart';
import 'package:kakikaki/features/diary/presentation/bloc/write/diary_write_bloc.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';

class DiaryWritePage extends StatefulWidget {
  const DiaryWritePage({
    super.key,
    required this.initialDate,
    required this.initialTopic,
    this.initialTopicKo = '',
    this.initialContent = '',
    this.diaryId,
  });

  final DateTime initialDate;
  final String initialTopic;
  final String initialTopicKo;
  final String initialContent;
  final String? diaryId;

  @override
  State<DiaryWritePage> createState() => _DiaryWritePageState();
}

class _DiaryWritePageState extends BaseScaffoldPageState<DiaryWritePage,
    DiaryWriteBloc, DiaryWriteState> {
  _DiaryWritePageState()
      : super(
          horizontalMargin: 0,
          verticalMargin: 0,
          isBottomNavigationBar: false,
          backgroundColor: Palette.gray10,
        );
  late final TextEditingController _controller;
  bool _isRequestingFeedback = false;
  bool _isTopicExpanded = false;
  late StreamSubscription _globalBlocSubscription;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    bloc.setInitialTopic(widget.initialTopic, widget.initialTopicKo);

    // GlobalBloc을 구독해서 프리미엄 상태가 바뀌면 화면(글자수) 즉시 새로고침
    _globalBlocSubscription = getIt<GlobalBloc>().stream.listen((globalState) {
      safeSetState(() {});
    });

    if (widget.initialContent.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.text = widget.initialContent;
      });
    }
    if (widget.initialTopic.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) bloc.changeTopic();
      });
    }
  }

  @override
  void dispose() {
    _globalBlocSubscription.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  String get appBarTitle => context.l10n.diary_write_appbar_date(
        widget.initialDate.month,
        widget.initialDate.day,
        WeekdayUtils.getFullWeekdayNameSync(
            widget.initialDate.weekday, context.l10n),
      );

  @override
  Widget buildPage(BuildContext context, DiaryWriteState state) {
    final isPremium = getIt<GlobalBloc>().state.isPremium;
    final int maxLength = isPremium ? 1000 : 300;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTopicCard(context),
              Align(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: _showVocabularyPeekSheet,
                  icon: Icon(Icons.menu_book_rounded,
                      size: 18, color: context.palette.primary),
                  label: Text(context.l10n.diary_write_vocabulary_peek,
                      style: context.h7_600Style
                          .copyWith(color: context.palette.primary)),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: context.screenHeight * 0.43,
                decoration: BoxDecoration(
                    color: context.palette.onSurface,
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(16),
                child: CommonTextFormField(
                  inputFormatters: const [NoLeadingWhitespaceFormatter()],
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  maxLength: maxLength,
                  minLines: 10,
                  maxLines: 100,
                  hintText: context.l10n.diary_write_hint,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  showCharacterCount: true,
                  fillColor: context.palette.surface,
                  characterCountStyle: context.h6_400Style
                      .copyWith(color: context.palette.surface),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.diary_write_feedback_min_length,
                  style: context.h8_400Style.copyWith(color: Palette.gray50)),
              const SizedBox(height: 10),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, child) {
                  final isEnabled =
                      value.text.trim().length >= 10 && !_isRequestingFeedback;
                  return CommonElevatedButton(
                    text: context.l10n.diary_write_feedback_request,
                    backgroundColor: isEnabled ? Palette.black : Palette.gray20,
                    enabledTextColor: Palette.white,
                    isEnabled: isEnabled,
                    onPressed: _onRequestFeedback,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopicCard(BuildContext context) {
    final topic =
        bloc.state.topic.isNotEmpty ? bloc.state.topic : widget.initialTopic;
    final topicKo = bloc.state.topicKo.isNotEmpty
        ? bloc.state.topicKo
        : widget.initialTopicKo;

    // 1. 현재 앱의 언어 코드를 확인합니다.
    final currentLanguage = getIt<GlobalBloc>().state.languageCode;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: context.palette.onSurface,
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                safeSetState(() => _isTopicExpanded = !_isTopicExpanded),
            child: Row(
              children: [
                Text(context.l10n.home_topic,
                    style: context.h6_600Style
                        .copyWith(color: context.palette.surface)),
                IconButton(
                  icon: Icon(Icons.change_circle_rounded,
                      color: context.palette.surface, size: 22),
                  onPressed: () => bloc.changeTopic(),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const Spacer(),
                Icon(_isTopicExpanded ? Icons.expand_less : Icons.expand_more,
                    color: context.palette.surface),
              ],
            ),
          ),
          if (_isTopicExpanded) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...topic.split('\n').map((line) => Text(line,
                      style: context.h7_400Style
                          .copyWith(color: context.palette.onSurface))),

                  // 2. topicKo가 비어있지 않고, 현재 언어가 'ja'(일본어)가 아닐 때만 번역을 렌더링합니다.
                  if (topicKo.isNotEmpty && currentLanguage != 'ja') ...[
                    const SizedBox(height: 4),
                    Text(topicKo,
                        style: context.h8_400Style
                            .copyWith(color: Palette.gray50)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showVocabularyPeekSheet() {
    FocusScope.of(context).unfocus();

    final vocabBloc = getIt<VocabularyListBloc>();
    if (vocabBloc.state.allItems.isEmpty) {
      vocabBloc.add(const VocabularyListEvent.initialized());
    }

    context.showModalCommonBottomSheet(
      CommonBottomSheet(
        isDragHandle: true,
        heightFactor: 0.65, // 화면의 65% 높이 차지
        child: SizedBox(
          // ConstrainedBox 내부에서 Expanded가 무한정 커지는 걸 방지하기 위해 높이 고정
          height: context.screenHeight * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BubbleContainer(
                  text: context.l10n.diary_write_tap_to_insert,
                  arrowDirection: ArrowDirection.bottomCenter,
                  width: double.infinity,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<VocabularyListBloc, VocabularyListState>(
                  bloc: vocabBloc,
                  builder: (context, vocabState) {
                    if (vocabState.allItems.isEmpty) {
                      return Center(
                        child: Text(
                          context.l10n.diary_write_no_words,
                          style: context.h6_400Style
                              .copyWith(color: Palette.gray50),
                        ),
                      );
                    }

                    final items = vocabState.allItems;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _insertWordToDiary(item.word),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Palette.gray10,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Palette.gray20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RubyText(
                                  text: (item.ruby != null &&
                                          item.ruby!.isNotEmpty)
                                      ? item.ruby!
                                      : item.word,
                                  baseStyle: context.h4_700Style,
                                  usePopup: false,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.meaningTranslated,
                                  style: context.h6_400Style
                                      .copyWith(color: Palette.gray70),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _insertWordToDiary(String wordToInsert) {
    final text = _controller.text;
    final selection = _controller.selection;

    final newText = text.replaceRange(
      selection.start > -1 ? selection.start : text.length,
      selection.end > -1 ? selection.end : text.length,
      wordToInsert,
    );

    _controller.text = newText;

    _controller.selection = TextSelection.collapsed(
      offset: (selection.start > -1 ? selection.start : text.length) +
          wordToInsert.length,
    );

    Navigator.pop(context);
    FocusScope.of(context).requestFocus();
  }

  Future<void> _onRequestFeedback() async {
    if (_controller.text.trim().length < 10) return;
    if (_isRequestingFeedback) return;
    safeSetState(() => _isRequestingFeedback = true);
    try {
      final payload = DiaryWritePayload(
        date: widget.initialDate,
        topic: bloc.state.topic.isNotEmpty
            ? bloc.state.topic
            : widget.initialTopic,
        content: _controller.text.trim(),
        diaryId: widget.diaryId,
      );
      final result = await context.push<bool>('/diary/processing',
          extra: jsonEncode(payload.toJson()));
      if (mounted && result == true) context.pop(true);
    } finally {
      safeSetState(() => _isRequestingFeedback = false);
    }
  }
}
