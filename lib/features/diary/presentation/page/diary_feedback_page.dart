import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/router/router.dart';
import 'package:kakikaki/app/widget/dialogue/diary_usage_helper.dart';
import 'package:kakikaki/app/widget/dialogue/premium_dialog_hleper.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/app/widget/view/empty_state_widget.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/weekday_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_flow_models.dart';
import 'package:kakikaki/features/diary/presentation/bloc/feedback/diary_feedback_bloc.dart';
import 'package:kakikaki/features/diary/presentation/widgets/ruby_text_with_highlights.dart';

class DiaryFeedbackPage extends StatefulWidget {
  const DiaryFeedbackPage(
      {super.key, required this.result, this.fromHome = false});

  final DiaryFeedbackResult result;
  final bool fromHome;

  @override
  State<DiaryFeedbackPage> createState() => _DiaryFeedbackPageState();
}

class _DiaryFeedbackPageState extends BaseScaffoldPageState<DiaryFeedbackPage,
    DiaryFeedbackBloc, DiaryFeedbackState> with SingleTickerProviderStateMixin {
  _DiaryFeedbackPageState()
      : super(
            backgroundColor: Palette.gray10,
            horizontalMargin: 0,
            verticalMargin: 0,
            isBottomNavigationBar: false,
            automaticallyImplyLeading: true);

  bool _hasPopped = false;
  bool _canPop = false;

  bool _showCorrected = false;
  bool _showFurigana = true;

  final ScrollController _recommendationScrollController = ScrollController();
  late final TabController _tabController;

  bool get _isFailed =>
      widget.result.recommendations.isEmpty &&
      widget.result.spellingFeedback.isEmpty &&
      widget.result.correctedText == widget.result.originalText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _showCorrected = widget.result.spellingFeedback.isNotEmpty &&
        widget.result.correctedText != widget.result.originalText;

    bloc.add(DiaryFeedbackEvent.loadBookmarksRequested(
        diaryId: widget.result.diaryId,
        recommendations: widget.result.recommendations));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _recommendationScrollController.dispose();
    super.dispose();
  }

  @override
  VoidCallback? get appBarLeadingActionGetter => () => _handleBackPressed();

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async {
    bloc.add(DiaryFeedbackEvent.loadBookmarksRequested(
        diaryId: widget.result.diaryId,
        recommendations: widget.result.recommendations,
        forceRefresh: true));
  }

  @override
  String get appBarTitle {
    final localDate = widget.result.date.toLocal();

    return context.l10n.diary_write_appbar_date(
      localDate.month,
      localDate.day,
      WeekdayUtils.getFullWeekdayNameSync(localDate.weekday, context.l10n),
    );
  }

  @override
  Widget buildPage(BuildContext context, DiaryFeedbackState state) {
    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackPressed();
      },
      child: Stack(
        children: [
          CommonTabWidget(
            tabs: [
              TabItem(
                  title: context.l10n.feedback,
                  content: _buildGrammarTab(state)),
              TabItem(
                  title: context.l10n.diary_feedback_tab_recommendation,
                  content: _buildRecommendationTab(state)),
            ],
            tabController: _tabController,
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: CommonElevatedButton(
              text: context.l10n.diary_feedback_go_home,
              backgroundColor: Palette.black,
              enabledTextColor: Palette.white,
              onPressed: _goHome,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void handleBlocStateListener(BuildContext context, DiaryFeedbackState state) {
    super.handleBlocStateListener(context, state);

    // 1. 프리미엄 단어 제한 팝업 (빌드/시맨틱 단계와 겹치면 parentDataDirty가 날 수 있어 프레임 이후 표시)
    if (state.isPremiumLimitReached) {
      bloc.add(const DiaryFeedbackEvent.premiumPopupShown());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        PremiumDialogHelper.showPremiumGuide(
          context,
          message: context.l10n.diary_feedback_free_limit_50,
        );
      });
    }

    // 일기 삭제가 완료되었을 때의 라우팅 처리
    if (state.isDeleted) {
      if (widget.fromHome) {
        context.go('/home');
      } else {
        context.pop(true); // true를 넘겨 홈 화면이 새로고침 되도록 유도할 수 있습니다.
      }
    }
  }

  @override
  List<Widget>? get rightAppBarActions => [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.white),
          onPressed: () => _onEditPressed(context),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: () => _onDeletePressed(context),
        ),
      ];

  Widget _buildGrammarTab(DiaryFeedbackState state) {
    final spellings = widget.result.spellingFeedback;
    final originalDisplayText = _resolveOriginalDisplayText();
    final correctedDisplayText = _resolveCorrectedDisplayText();

    // 💡 변경: SingleChildScrollView 대신 CustomScrollView를 사용합니다.
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isFailed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: context.palette.error.withExactOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.palette.error),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: context.palette.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.l10n.diary_feedback_analysis_failed,
                            style: context.h7_600Style
                                .copyWith(color: context.palette.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.l10n.diary_feedback_furigana,
                        style: context.h6_600Style),
                    const SizedBox(width: 4),
                    Switch(
                      value: _showFurigana,
                      onChanged: (widget.result.contentFurigana.isNotEmpty ||
                              widget.result.correctedContentFurigana.isNotEmpty)
                          ? (value) => safeSetState(() => _showFurigana = value)
                          : null,
                      activeThumbColor: context.palette.primary,
                    ),
                    const SizedBox(width: 16),
                    Text(context.l10n.diary_feedback_corrected,
                        style: context.h6_600Style),
                    Switch(
                      value: _showCorrected,
                      onChanged: !_isFailed &&
                              widget.result.spellingFeedback.isNotEmpty &&
                              widget.result.correctedText !=
                                  widget.result.originalText
                          ? (value) =>
                              safeSetState(() => _showCorrected = value)
                          : null,
                      activeThumbColor: context.palette.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Palette.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: _showCorrected
                      ? _buildCorrectedDiaryText(
                          correctedDisplayText, _showFurigana)
                      : RubyText(
                          text: originalDisplayText,
                          baseStyle: context.h6_400Style,
                          isFuriganaVisible: _showFurigana),
                ),
                const SizedBox(height: 20),
                Text(
                    _isFailed
                        ? context.l10n.diary_feedback_grammar_title
                        : context.l10n
                            .diary_feedback_grammar_count(spellings.length),
                    style: context.h6_600Style),
                const SizedBox(height: 12),
                if (spellings.isNotEmpty)
                  ...spellings.map((spelling) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Palette.white,
                            borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RubyText(
                                text: '${spelling.original}',
                                baseStyle: context.h5_500Style),
                            const SizedBox(height: 6),
                            RubyText(
                                text: spelling.corrected,
                                baseStyle: context.h5_600Style
                                    .copyWith(color: context.palette.error)),
                            const Divider(height: 22),
                            RubyText(
                                text: spelling.reason,
                                baseStyle: context.h6_400Style),
                          ],
                        ),
                      ))
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Palette.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(
                      _isFailed
                          ? context.l10n.diary_feedback_no_feedback
                          : context.l10n.diary_feedback_no_error_found,
                      style: context.h6_400Style,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationTab(DiaryFeedbackState state) {
    final languageCode = getIt<GlobalBloc>().state.languageCode;
    final recommendations = widget.result.recommendations;

    // 💡 변경: Column과 Expanded를 제거하고 순수 ListView만 반환합니다.
    return ListView(
      controller: _recommendationScrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        ...recommendations.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isBookmarked = state.bookmarkedIndices.contains(index);
          return Container(
            key: ValueKey(
                'diary_feedback_rec_${widget.result.diaryId}_$index'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Palette.white, borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CommonChip(
                        label: item.type == 'grammar'
                            ? context.l10n.diary_feedback_chip_grammar
                            : context.l10n.diary_feedback_chip_vocabulary,
                        labelColor: context.palette.onPrimary,
                        backgroundColor: context.palette.primary),
                    const SizedBox(width: 6),
                    CommonChip(label: item.level.nameString),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          color: isBookmarked
                              ? context.palette.primary
                              : Palette.gray50),
                      onPressed: () => bloc.add(
                          DiaryFeedbackEvent.bookmarkToggled(
                              index: index,
                              item: item,
                              diaryId: widget.result.diaryId)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RubyText(
                    text: (item.ruby != null && item.ruby!.isNotEmpty)
                        ? item.ruby!
                        : item.word,
                    baseStyle: context.h4_700Style.copyWith(height: 1.2)),
                if (item.meaningTranslated.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  RubyText(
                      text: item.meaningTranslated,
                      baseStyle: context.h6_600Style),
                ],
                const SizedBox(height: 8),
                if (item.type == 'grammar' && item.connection.isNotEmpty) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Palette.gray10, borderRadius: Dimens.tagRadius),
                    child: Text(
                        context.l10n
                            .diary_feedback_connection_format(item.connection),
                        style: context.h7_600Style),
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.exampleJp.isNotEmpty)
                  RubyText(
                      text: item.exampleJp,
                      baseStyle:
                          context.h6_400Style.copyWith(color: Palette.gray70)),
                if (item.exampleTranslated.isNotEmpty &&
                    languageCode == 'ko') ...[
                  Text(item.exampleTranslated,
                      style:
                          context.h7_400Style.copyWith(color: Palette.gray60)),
                ],
                if (item.exampleEn.isNotEmpty && languageCode == 'en')
                  Text(item.exampleEn,
                      style:
                          context.h7_400Style.copyWith(color: Palette.gray50)),
              ],
            ),
          );
        }),
        if (!commonState.isLoading &&
            !commonState.isError &&
            recommendations.isEmpty)
          EmptyStateWidget(
            shrinkWrap: true,
            icon: Icons.lightbulb_outline,
            text: _isFailed
                ? context.l10n.diary_feedback_no_recommendation_failed
                : context.l10n.diary_feedback_no_recommendation,
            topPadding: 160,
          ),
      ],
    );
  }

  Future<void> _onEditPressed(BuildContext context) async {
    // 내용을 수정해서 재분석을 받는 것은 '새 일기'와 동일하게 취급합니다.
    final canWrite = await DiaryUsageHelper.checkCanWriteToday(context);
    if (!canWrite) return; // 횟수가 없으면 팝업 띄우고 진입 차단!

    final originalText = widget.result.originalText;
    final correctedText = widget.result.correctedText;
    final hasCorrected = !_isFailed &&
        correctedText.isNotEmpty &&
        correctedText != originalText &&
        widget.result.spellingFeedback.isNotEmpty;

    String selectedContent;
    if (hasCorrected) {
      final choice = await CommonDialogue.showTwoChoiceDialogue<String>(
        context: context,
        title: context.l10n.diary_feedback_edit_choice_title,
        content: context.l10n.diary_feedback_edit_choice_content,
        outlineButtonText: context.l10n.diary_feedback_edit_choice_original,
        elevatedButtonText: context.l10n.diary_feedback_edit_choice_corrected,
        outlineResult: 'original',
        elevatedResult: 'corrected',
        onOutlinedButtonPressed: () {},
        onElevatedButtonPressed: () {},
      );
      if (choice == null || !mounted) return;
      selectedContent = choice == 'original' ? originalText : correctedText;
    } else {
      selectedContent = originalText;
    }

    final result = await DiaryWriteRoute(
      dateMillis: widget.result.date.millisecondsSinceEpoch,
      topic: '',
      topicKo: '',
      initialContent: selectedContent,
      diaryId: widget.result.diaryId,
    ).push<bool>(context);

    if (result == true && mounted) _popWithResult(true);
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: context.l10n.diary_feedback_delete_title,
      content: context.l10n.diary_feedback_delete_content,
      outlineButtonText: context.l10n.action_cancel,
      elevatedButtonText: context.l10n.action_delete,
    );
    if (confirmed != true || !mounted) return;
    bloc.add(DiaryFeedbackEvent.deleteRequested(
        diaryId: widget.result.diaryId, date: widget.result.date));
  }

  Future<bool> _handleBackPressed() async {
    if (widget.fromHome || bloc.state.hasBookmarkChanged) {
      _goHome();
      return false;
    }
    if (context.canPop())
      _popWithResult(false);
    else
      _goHome();
    return false;
  }

  String _resolveOriginalDisplayText() {
    final originalText = widget.result.originalText;
    final originalFurigana = widget.result.contentFurigana;
    if (originalFurigana.isEmpty || !originalFurigana.contains('['))
      return originalText;

    final stripped = _stripRubyMarkup(originalFurigana);
    final normalizedOriginal = _normalizeForCompare(originalText);
    final normalizedStripped = _normalizeForCompare(stripped);

    if (normalizedStripped == normalizedOriginal ||
        (normalizedStripped.length - normalizedOriginal.length).abs() < 5)
      return originalFurigana;
    return originalText;
  }

  String _resolveCorrectedDisplayText() {
    final correctedText = widget.result.correctedText;
    final correctedFurigana = widget.result.correctedContentFurigana;
    if (correctedFurigana.isEmpty || !correctedFurigana.contains('['))
      return correctedText;

    final stripped = _stripRubyMarkup(correctedFurigana);
    final normalizedCorrected = _normalizeForCompare(correctedText);
    final normalizedStripped = _normalizeForCompare(stripped);

    if (normalizedStripped == normalizedCorrected) return correctedFurigana;
    final originalText = widget.result.originalText;
    if (originalText.isNotEmpty &&
        originalText != correctedText &&
        _normalizeForCompare(originalText) == normalizedStripped)
      return correctedText;
    return correctedFurigana;
  }

  String _stripRubyMarkup(String text) => text.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'), (match) => match.group(1) ?? '');
  String _normalizeForCompare(String text) => text
      .replaceAll(RegExp(r'\s+'), '')
      .replaceAll('\u3000', '')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '')
      .trim();

  void _popWithResult(bool result) {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    _canPop = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop(result);
    });
  }

  void _goHome() {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    context.go('/home');
  }
}

extension DiaryCorrectedTextExtension on _DiaryFeedbackPageState {
  Widget _buildCorrectedDiaryText(
      String correctedTextWithFurigana, bool isFuriganaVisible) {
    final original = widget.result.originalText;
    final corrected = widget.result.correctedText;
    final feedbacks = widget.result.spellingFeedback;

    // 💡 핵심 픽스: 하이라이트할 텍스트 중 빈 문자열("")이나 공백은 제거합니다.
    // AI가 단어를 '삭제'하라고 추천한 경우 corrected가 ""로 넘어오는데,
    // 빈 문자열을 하이라이트하려고 하면 렌더링 엔진이 뻗어버립니다.
    final validHighlights = feedbacks
        .map((f) => f.corrected)
        .where((text) => text.trim().isNotEmpty)
        .toList();

    // 유효한 하이라이트가 없으면 일반 RubyText 반환
    if (validHighlights.isEmpty || corrected.isEmpty) {
      return RubyText(
          text: correctedTextWithFurigana.isEmpty
              ? (corrected.isEmpty ? original : corrected)
              : correctedTextWithFurigana,
          baseStyle: context.h6_500Style,
          isFuriganaVisible: isFuriganaVisible);
    }

    // 빈 문자열이 제거된 안전한 목록(validHighlights)으로 렌더링
    return RubyTextWithHighlights(
        text: correctedTextWithFurigana.isNotEmpty
            ? correctedTextWithFurigana
            : corrected,
        baseStyle: context.h6_500Style,
        highlights: validHighlights,
        highlightColor: context.palette.error,
        isFuriganaVisible: isFuriganaVisible);
  }
}
