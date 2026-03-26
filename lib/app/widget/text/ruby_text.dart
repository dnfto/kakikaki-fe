import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/app/widget/dialogue/kanji_practice_dialog.dart';

class RubyText extends StatelessWidget {
  const RubyText({
    super.key,
    required this.text,
    required this.baseStyle,
    this.onKanjiTap,
    this.isFuriganaVisible = true,
    this.usePopup = true,
  });

  final String text;
  final TextStyle baseStyle;
  final void Function(String kanji)? onKanjiTap;
  final bool isFuriganaVisible;
  final bool usePopup;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    // 💡 1. 폰트 폴백 방지: 테마에서 명시적인 폰트 사이즈를 강제로 가져옵니다.
    final defaultStyle = DefaultTextStyle.of(context).style;
    final TextStyle resolvedStyle = defaultStyle.merge(baseStyle);
    final double baseSize = resolvedStyle.fontSize ?? 14.0;

    final double safeLineHeight = 1.8;

    // 바깥쪽 본문 스타일
    final safeBaseStyle = resolvedStyle.copyWith(
      fontSize: baseSize,
      height: safeLineHeight,
    );

    // 💡 2. 높이 클리핑 방지: iOS에서 1.1은 한자 위아래를 깎아먹습니다. 1.25로 여유를 줍니다.
    final kanjiInnerStyle = resolvedStyle.copyWith(
      fontSize: baseSize,
      height: 1.25,
    );

    final regex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final matches = regex.allMatches(text);

    // ==========================================================
    // 1. [한자](독음) 패턴이 없는 경우
    // ==========================================================
    if (matches.isEmpty) {
      if (onKanjiTap == null && !usePopup) {
        return Text(text,
            style: safeBaseStyle, textScaler: TextScaler.noScaling);
      }

      final kanjiRegex = RegExp(r'[\u4e00-\u9faf]');
      final kanjiMatches = kanjiRegex.allMatches(text);

      if (kanjiMatches.isEmpty) {
        return Text(text,
            style: safeBaseStyle, textScaler: TextScaler.noScaling);
      }

      final spans = <InlineSpan>[];
      int cursor = 0;
      for (final m in kanjiMatches) {
        if (m.start > cursor) {
          spans.add(TextSpan(
              text: text.substring(cursor, m.start), style: safeBaseStyle));
        }
        final kanji = m.group(0)!;
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () {
                if (usePopup) {
                  KanjiPracticeDialog.show(context: context, kanji: kanji);
                } else {
                  onKanjiTap?.call(kanji);
                }
              },
              child: Text(
                kanji,
                style: safeBaseStyle,
                textScaler: TextScaler.noScaling, // 💡 기기 폰트 설정 무시
              ),
            ),
          ),
        );
        cursor = m.end;
      }
      if (cursor < text.length) {
        spans.add(TextSpan(text: text.substring(cursor), style: safeBaseStyle));
      }

      return RichText(
        text: TextSpan(children: spans),
        strutStyle: StrutStyle(
          fontSize: baseSize,
          height: safeLineHeight,
          forceStrutHeight: true,
        ),
        textScaler: TextScaler.noScaling,
      );
    }

    // ==========================================================
    // 2. [한자](독음) 패턴이 있는 경우 (후리가나 렌더링)
    // ==========================================================
    final spans = <InlineSpan>[];
    int cursor = 0;

    final rubySize = (baseSize * 0.55).clamp(10.0, baseSize - 2);
    final rubyStyle = resolvedStyle.copyWith(
      fontSize: rubySize,
      color: isFuriganaVisible ? Palette.gray40 : Colors.transparent,
      height: 1.0,
      letterSpacing: 0,
    );

    for (final m in matches) {
      if (m.start > cursor) {
        spans.add(TextSpan(
            text: text.substring(cursor, m.start), style: safeBaseStyle));
      }

      final kanji = m.group(1)!;
      final ruby = m.group(2)!;

      final kanjiRegex = RegExp(r'[\u4e00-\u9faf]');
      final kanjiMatches = kanjiRegex.allMatches(kanji);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            verticalDirection: VerticalDirection.up,
            children: [
              // 💡 3. 소수점 픽셀 깨짐 방지: Wrap 대신 Row를 사용해 iOS Retina 해상도 오류 방지
              Row(
                mainAxisSize: MainAxisSize.min,
                children: kanjiMatches.isEmpty
                    ? [
                        GestureDetector(
                          onTap: () {
                            if (usePopup)
                              KanjiPracticeDialog.show(
                                  context: context, kanji: kanji);
                            else
                              onKanjiTap?.call(kanji);
                          },
                          child: Text(
                            kanji,
                            style: kanjiInnerStyle,
                            textScaler: TextScaler.noScaling, // 💡 필수!
                          ),
                        )
                      ]
                    : kanjiMatches.map((km) {
                        final singleKanji = km.group(0)!;
                        return GestureDetector(
                          onTap: () {
                            if (usePopup)
                              KanjiPracticeDialog.show(
                                  context: context, kanji: singleKanji);
                            else
                              onKanjiTap?.call(singleKanji);
                          },
                          child: Text(
                            singleKanji,
                            style: kanjiInnerStyle,
                            textScaler: TextScaler.noScaling, // 💡 필수!
                          ),
                        );
                      }).toList(),
              ),
              Text(
                ruby,
                style: rubyStyle,
                textScaler: TextScaler.noScaling, // 💡 필수!
              ),
            ],
          ),
        ),
      );
      cursor = m.end;
    }

    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: safeBaseStyle));
    }

    return RichText(
      text: TextSpan(children: spans),
      strutStyle: StrutStyle(
        fontSize: baseSize,
        height: safeLineHeight,
        forceStrutHeight: true,
      ),
      textScaler: TextScaler.noScaling,
    );
  }
}
