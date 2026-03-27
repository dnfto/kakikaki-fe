import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';

import 'package:kakikaki/app/widget/kanji/kanji_practice_widget.dart';
import 'package:kakikaki/app/widget/text/ruby_text.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/study/domain/model/study_entry.dart';

class StudyCardWidget extends StatefulWidget {
  const StudyCardWidget({
    super.key,
    required this.entry,
    required this.flipAnimation,
    required this.isFlipped,
    required this.onTap,
    required this.examples,
    required this.isLoadingExamples,
  });

  final StudyEntry entry;
  final Animation<double> flipAnimation;
  final bool isFlipped;
  final VoidCallback onTap;
  final List<Map<String, dynamic>> examples;
  final bool isLoadingExamples;

  @override
  State<StudyCardWidget> createState() => _StudyCardWidgetState();
}

class _StudyCardWidgetState extends State<StudyCardWidget> {
  bool _isPracticeMode = false;

  void _setPracticeMode(bool value) {
    setState(() => _isPracticeMode = value);
  }

  @override
  void didUpdateWidget(covariant StudyCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isFlipped && _isPracticeMode) {
      setState(() => _isPracticeMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.flipAnimation,
      builder: (context, child) {
        final angle = widget.flipAnimation.value * 3.14159;
        final isFlippedNow = widget.flipAnimation.value >= 0.5;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!_isPracticeMode) widget.onTap();
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isFlippedNow
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.14159),
                    child: _StudyCardBack(
                      entry: widget.entry,
                      examples: widget.examples,
                      isLoadingExamples: widget.isLoadingExamples,
                      onPracticeModeChanged: _setPracticeMode,
                    ),
                  )
                : _StudyCardFront(entry: widget.entry),
          ),
        );
      },
    );
  }
}

class _StudyCardFront extends StatelessWidget {
  const _StudyCardFront({required this.entry});
  final StudyEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: context.isTablet
          ? context.screenHeight * 0.6
          : context.screenHeight * 0.5,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withExactOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(builder: (context) {
                final languageCode = getIt<GlobalBloc>().state.languageCode;
                return CommonChip(label: entry.pos.getLabel(languageCode));
              }),
              const SizedBox(width: 6),
              CommonChip(label: entry.level.nameString),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                // 뒷면과 동일한 텍스트를 주되, 후리가나만 투명하게 숨겨서 뒷면 단어랑 높이 맞추기
                RubyText(
                  text: (entry.ruby != null && entry.ruby!.isNotEmpty)
                      ? entry.ruby!
                      : entry.word,
                  baseStyle: context.h2_700Style,
                  isFuriganaVisible: false,
                )
              ],
            ),
          ),
          const Spacer(),
          Center(
            child: Text(
              context.l10n.study_card_tap_to_reveal,
              style:
                  context.h8_600Style.copyWith(color: context.palette.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StudyCardBack extends StatefulWidget {
  const _StudyCardBack({
    required this.entry,
    required this.examples,
    required this.isLoadingExamples,
    required this.onPracticeModeChanged,
  });

  final StudyEntry entry;
  final List<Map<String, dynamic>> examples;
  final bool isLoadingExamples;
  final ValueChanged<bool> onPracticeModeChanged;

  @override
  State<_StudyCardBack> createState() => _StudyCardBackState();
}

class _StudyCardBackState extends State<_StudyCardBack> {
  late ScrollController _scrollController;
  bool _canScroll = false;
  bool _isAtBottom = false;
  bool _isPracticeMode = false;

  // 무거운 정규표현식을 static final로 캐싱하여 렌더링 성능 극대화
  static final _rubyTagRegex = RegExp(r'\[([^\]]+)\]\([^)]+\)');
  static final _kanjiTagRegex = RegExp(r'([\u4E00-\u9FFF]+)\[([ぁ-ゖァ-ヺー]+)\]');
  static final _whitespaceRegex = RegExp(r'\s+');
  static final _kanjiExtractRegex = RegExp(r'[\u4E00-\u9FFF]');

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScrollability());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _StudyCardBack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoadingExamples && !widget.isLoadingExamples) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _checkScrollability());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (mounted) {
      setState(() {
        _canScroll = maxScroll > 0;
        _isAtBottom = currentScroll >= maxScroll - 10;
      });
    }
  }

  void _checkScrollability() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _onScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Container(
      width: double.infinity,
      height: context.isTablet
          ? context.screenHeight * 0.6
          : context.screenHeight * 0.5,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withExactOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: _isPracticeMode
                ? AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    child: _buildPracticeContent(entry))
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Column(
                        key: const ValueKey('back-content'),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Builder(builder: (context) {
                              final languageCode =
                                  getIt<GlobalBloc>().state.languageCode;
                              return CommonChip(
                                  label: entry.pos.getLabel(languageCode));
                            }),
                            const SizedBox(width: 6),
                            CommonChip(label: entry.level.nameString)
                          ]),
                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              RubyText(
                                text: (entry.ruby != null &&
                                        entry.ruby!.isNotEmpty)
                                    ? entry.ruby!
                                    : entry.word,
                                baseStyle: context.h2_700Style,
                              )
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (entry.meaningTranslated.isNotEmpty) ...[
                            Text(context.l10n.study_label_meaning,
                                style: context.h5_600Style),
                            const SizedBox(height: 4),
                            Text(entry.meaningTranslated,
                                style: context.h6_400Style
                                    .copyWith(color: Palette.gray70))
                          ],
                          const SizedBox(height: 16),
                          if (entry.type == 'grammar' &&
                              entry.connection.isNotEmpty) ...[
                            Text('접속법', style: context.h5_600Style),
                            const SizedBox(height: 8),
                            Text(entry.connection,
                                style: context.h6_400Style
                                    .copyWith(color: Palette.gray70)),
                            const SizedBox(height: 16)
                          ],
                          if (entry.exampleJp.isNotEmpty ||
                              entry.exampleTranslated.isNotEmpty) ...[
                            Row(
                              children: [
                                Text(
                                  context.l10n.study_label_example,
                                  style: context.h5_600Style,
                                ),
                                const SizedBox(width: 6),
                                CommonTooltip(
                                  message: context.l10n
                                      .study_card_other_examples_translation_info,
                                  direction: TooltipDirection.right,
                                  iconSize: 18,
                                  iconColor: Palette.gray50,
                                  backgroundColor: Palette.gray80,
                                  textStyle: context.h8_400Style
                                      .copyWith(color: Palette.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (entry.exampleJp.isNotEmpty)
                              RubyText(
                                  text: entry.exampleJp,
                                  baseStyle: context.h6_400Style
                                      .copyWith(color: Palette.gray70)),
                            if (entry.exampleTranslated.isNotEmpty &&
                                getIt<GlobalBloc>().state.languageCode !=
                                    'ja') ...[
                              const SizedBox(height: 4),
                              Text(entry.exampleTranslated,
                                  style: context.h7_400Style
                                      .copyWith(color: Palette.gray60))
                            ]
                          ],

                          // 지저분한 익명함수를 분리하고 최적화된 Iterable 활용
                          ..._buildOtherExamples(entry),

                          if (widget.isLoadingExamples) ...[
                            const SizedBox(height: 16),
                            const Center(
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
          if (_isPracticeMode)
            Center(
                child: TextButton(
                    onPressed: () {
                      setState(() => _isPracticeMode = false);
                      widget.onPracticeModeChanged(false);
                    },
                    child: Text('카드 뒷면으로 돌아가기',
                        style: context.h8_600Style
                            .copyWith(color: context.palette.primary))))
          else if (_canScroll && !_isAtBottom)
            Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                    child: Text('아래로 스크롤하기',
                        style: context.h8_400Style.copyWith(
                            color: Palette.gray40,
                            fontStyle: FontStyle.italic)))),
        ],
      ),
    );
  }

  // 예문 생성 및 필터링 로직 분리 & Iterable 최적화 적용
  // 예문 생성 및 필터링 로직 분리 & Iterable 최적화 적용
  List<Widget> _buildOtherExamples(StudyEntry entry) {
    if (widget.examples.isEmpty) return [];

    final mainKey = _normalizeExampleJp(entry.exampleJp);
    final seen = <String>{if (mainKey.isNotEmpty) mainKey};

    // 1. 현재 앱의 언어 코드를 가져옵니다 (예: 'ko', 'en', 'ja' 등)
    final currentLanguageCode = getIt<GlobalBloc>().state.languageCode;

    // Dart의 Iterable(where, take)을 활용한 초고속 필터링 (최대 5개 매칭 시 즉시 루프 종료)
    final uniqueExamples = widget.examples
        .where((example) {
          final jp =
              (example['jp'] ?? example['example_jp'] ?? '').toString().trim();
          if (jp.isEmpty) return false;

          final key = _normalizeExampleJp(jp);
          if (key.isEmpty || seen.contains(key)) return false;

          seen.add(key);
          return true;
        })
        .take(5)
        .toList();

    if (uniqueExamples.isEmpty) return [];

    return [
      const SizedBox(height: 16),
      Text(
        context.l10n.study_card_other_examples_title,
        style: context.h5_600Style,
      ),
      const SizedBox(height: 8),
      ...uniqueExamples.map((example) {
        final jp = (example['jp'] ?? example['example_jp'] ?? '').toString();

        // 수정된 부분: 언어 설정이 'ja'(일본어)일 때는 번역을 빈 문자열로 강제 처리합니다.
        String translation = '';
        if (currentLanguageCode != 'ja') {
          translation = (example[currentLanguageCode] ??
                  example['ko'] ??
                  example['en'] ??
                  example['example_translated'] ??
                  '')
              .toString();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Palette.gray10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RubyText(
                  text: '"$jp"',
                  baseStyle:
                      context.h7_400Style.copyWith(color: Palette.gray70),
                ),
                // translation이 빈 문자열이 되므로 이 아래 번역 텍스트 위젯은 아예 렌더링되지 않습니다.
                if (translation.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(translation,
                      style:
                          context.h8_400Style.copyWith(color: Palette.gray60)),
                ]
              ],
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildPracticeContent(StudyEntry entry) {
    final target = _extractKanjiTarget(entry.word);
    return SingleChildScrollView(
        child: Column(
            key: const ValueKey('practice-content'),
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [KanjiPracticeWidget(kanji: target)]));
  }

  String _normalizeExampleJp(String input) {
    var t = input.trim();
    if (t.length >= 2 && t.startsWith('"') && t.endsWith('"')) {
      t = t.substring(1, t.length - 1);
    }
    // 사전에 컴파일된 정규식 재사용
    t = t.replaceAllMapped(_rubyTagRegex, (m) => (m.group(1) ?? ''));
    t = t.replaceAllMapped(_kanjiTagRegex, (m) => (m.group(1) ?? ''));
    t = t.replaceAll(_whitespaceRegex, '');
    return t;
  }

  String _extractKanjiTarget(String input) {
    final matches = _kanjiExtractRegex.allMatches(input);
    if (matches.isEmpty) return input;
    return matches.map((m) => m.group(0)!).join();
  }
}
