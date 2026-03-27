import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/app/widget/dialogue/kanji_practice_dialog.dart';

class CleanTextResult {
  final String cleanText;
  final List<int> indexMap;
  CleanTextResult(this.cleanText, this.indexMap);
}

/// 루비 텍스트와 하이라이트를 함께 표시하는 위젯 (iOS 렌더링 완벽 대응)
class RubyTextWithHighlights extends StatefulWidget {
  const RubyTextWithHighlights({
    super.key,
    required this.text,
    required this.baseStyle,
    required this.highlights,
    required this.highlightColor,
    this.isFuriganaVisible = true,
  });

  final String text;
  final TextStyle baseStyle;
  final List<String> highlights;
  final Color highlightColor;
  final bool isFuriganaVisible;

  @override
  State<RubyTextWithHighlights> createState() => _RubyTextWithHighlightsState();
}

class _RubyTextWithHighlightsState extends State<RubyTextWithHighlights> {
// 제스처 메모리 누수 방지용 리스트
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TapGestureRecognizer _createRecognizer(String kanji) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () {
        KanjiPracticeDialog.show(context: context, kanji: kanji);
      };
    _recognizers.add(recognizer);
    return recognizer;
  }

  bool _isSpace(String ch) => ch.trim().isEmpty || ch == '　';

  CleanTextResult _getCleanTextAndMap(String originalText) {
    final sb = StringBuffer();
    final map = <int>[];
    int i = 0;

    while (i < originalText.length) {
      if (originalText[i] == '[') {
        int baseStart = i + 1;
        int baseEnd = originalText.indexOf(']', baseStart);
        if (baseEnd != -1) {
          int parenStart = baseEnd + 1;
          if (parenStart < originalText.length &&
              (originalText[parenStart] == '(' ||
                  originalText[parenStart] == '（')) {
            int parenEnd = originalText.indexOf(
                originalText[parenStart] == '(' ? ')' : '）', parenStart + 1);
            if (parenEnd != -1) {
              for (int j = baseStart; j < baseEnd; j++) {
                if (!_isSpace(originalText[j])) {
                  sb.write(originalText[j]);
                  map.add(j);
                }
              }
              i = parenEnd + 1;
              continue;
            }
          }
        }
      }
      if (!_isSpace(originalText[i])) {
        sb.write(originalText[i]);
        map.add(i);
      }
      i++;
    }
    map.add(originalText.length);
    return CleanTextResult(sb.toString(), map);
  }

  String _stripRuby(String raw) {
    return raw.replaceAllMapped(
        RegExp(r'\[([^\]]+)\][\(（][^)）]+[\)）]'), (m) => m.group(1)!);
  }

  bool _hasJapaneseOrEnglish(String s) {
    return RegExp(r'[a-zA-Zぁ-んァ-ン一-龯]').hasMatch(s);
  }

  List<String> _extractCandidates(String highlight) {
    String clean = _stripRuby(highlight);
    final parts = clean.split(RegExp(r'[/／]|\b또는\b|\b혹은\b|\(|（|\)|）'));
    final candidates = <String>[];

    for (var p in parts) {
      String stripped = p.replaceAll(RegExp(r'\s|　'), '');
      if (stripped.isNotEmpty && _hasJapaneseOrEnglish(stripped)) {
        candidates.add(stripped);
      }
    }
    return candidates;
  }

  String? _findBestSubstringMatch(String cleanText, String candidate) {
    if (cleanText.contains(candidate)) return candidate;

    int m = candidate.length;
    int n = cleanText.length;
    int maxLength = 0;
    int endIndex = 0;
    var table = List.generate(m + 1, (_) => List.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (candidate[i - 1] == cleanText[j - 1]) {
          table[i][j] = table[i - 1][j - 1] + 1;
          if (table[i][j] > maxLength) {
            maxLength = table[i][j];
            endIndex = i;
          }
        }
      }
    }
    if (maxLength >= 2 && maxLength >= (candidate.length / 2).floor()) {
      return candidate.substring(endIndex - maxLength, endIndex);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.text.isEmpty) return const SizedBox.shrink();

// 💡 1. 폰트 폴백 방지: 테마에서 명시적인 폰트 사이즈를 강제로 가져옵니다.
    final defaultStyle = DefaultTextStyle.of(context).style;
    final TextStyle resolvedStyle = defaultStyle.merge(widget.baseStyle);
    final double baseSize = resolvedStyle.fontSize ?? 14.0;

    final double safeLineHeight = 1.8;

// 바깥쪽 본문 스타일
    final normalStyle = resolvedStyle.copyWith(
      fontSize: baseSize,
      height: safeLineHeight,
    );

// 하이라이트 스타일
    final highlightStyle = normalStyle.copyWith(
      color: widget.highlightColor,
      fontWeight: FontWeight.bold,
    );

// 💡 2. 높이 클리핑 방지: iOS에서 1.1은 한자 위아래를 깎아먹습니다. 1.25로 여유를 줍니다.
    final kanjiInnerNormalStyle = resolvedStyle.copyWith(
      fontSize: baseSize,
      height: 1.25,
    );
    final kanjiInnerHighlightStyle = kanjiInnerNormalStyle.copyWith(
      color: widget.highlightColor,
      fontWeight: FontWeight.bold,
    );

    final cleanResult = _getCleanTextAndMap(widget.text);
    final cleanText = cleanResult.cleanText;
    final indexMap = cleanResult.indexMap;
    final highlightRanges = <_TextRange>[];

    for (final rawHighlight in widget.highlights) {
      if (rawHighlight.isEmpty) continue;

      final candidates = _extractCandidates(rawHighlight);
      String? bestMatch;
      int maxLen = 0;

      for (final cand in candidates) {
        final match = _findBestSubstringMatch(cleanText, cand);
        if (match != null && match.length > maxLen) {
          maxLen = match.length;
          bestMatch = match;
        }
      }

      if (bestMatch != null) {
        int start = 0;
        while (true) {
          final index = cleanText.indexOf(bestMatch, start);
          if (index == -1) break;

          int realStartIndex = indexMap[index];
          int realEndIndex = indexMap[index + bestMatch.length];
          highlightRanges.add(_TextRange(realStartIndex, realEndIndex));

          start = index + bestMatch.length;
        }
      }
    }
    highlightRanges.sort((a, b) => a.start.compareTo(b.start));

    final rubyRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    final rubyMatches = rubyRegex.allMatches(widget.text);

// ==========================================================
// 후리가나가 아예 없는 경우
// ==========================================================
    if (rubyMatches.isEmpty) {
      return _buildHighlightedText(widget.text, highlightRanges, normalStyle,
          highlightStyle, baseSize, safeLineHeight);
    }

// ==========================================================
// 후리가나가 있는 경우
// ==========================================================
    final spans = <InlineSpan>[];
    int cursor = 0;

    final rubySize = (baseSize * 0.6).clamp(10.0, baseSize - 2);
    final rubyStyle = resolvedStyle.copyWith(
      fontSize: rubySize,
      color: widget.isFuriganaVisible ? Palette.gray40 : Colors.transparent,
      height: 1.0,
      fontWeight: FontWeight.normal,
    );

    for (final m in rubyMatches) {
      if (m.start > cursor) {
        final beforeText = widget.text.substring(cursor, m.start);
        _addHighlightedSpansWithKanji(spans, beforeText, highlightRanges,
            cursor, normalStyle, highlightStyle);
      }

      final kanji = m.group(1)!;
      final ruby = m.group(2)!;
      final isHighlighted = _isInRange(m.start, m.end, highlightRanges);

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () {
              KanjiPracticeDialog.show(context: context, kanji: kanji);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              verticalDirection: VerticalDirection.up,
              children: [
                Text(
                  kanji,
// 💡 높이 클리핑 방지 스타일 적용 (1.25)
                  style: isHighlighted
                      ? kanjiInnerHighlightStyle
                      : kanjiInnerNormalStyle,
                  textScaler: TextScaler.noScaling, // 💡 iOS 크기 꼬임 방지
                ),
                Text(
                  ruby,
                  style: rubyStyle,
                  textScaler: TextScaler.noScaling, // 💡 iOS 크기 꼬임 방지
                ),
              ],
            ),
          ),
        ),
      );
      cursor = m.end;
    }

    if (cursor < widget.text.length) {
      final remainingText = widget.text.substring(cursor);
      _addHighlightedSpansWithKanji(spans, remainingText, highlightRanges,
          cursor, normalStyle, highlightStyle);
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

  Widget _buildHighlightedText(
      String text,
      List<_TextRange> ranges,
      TextStyle normalStyle,
      TextStyle highlightStyle,
      double baseSize,
      double safeLineHeight) {
    final spans = <InlineSpan>[];
    _addHighlightedSpansWithKanji(
        spans, text, ranges, 0, normalStyle, highlightStyle);

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

  void _addHighlightedSpansWithKanji(
    List<InlineSpan> spans,
    String textSegment,
    List<_TextRange> ranges,
    int textOffset,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    final kanjiRegex = RegExp(r'[\u4e00-\u9faf]');
    final matches = kanjiRegex.allMatches(textSegment);
    int cursor = 0;

    for (final m in matches) {
      if (m.start > cursor) {
        _addPlainHighlightedSpans(spans, textSegment.substring(cursor, m.start),
            ranges, textOffset + cursor, normalStyle, highlightStyle);
      }

      final kanji = m.group(0)!;
      final isHigh =
          _isInRange(textOffset + m.start, textOffset + m.end, ranges);

// 💡 [핵심 iOS 픽스] WidgetSpan + GestureDetector 대신 TextSpan + recognizer 사용
// 이렇게 하면 바깥 글씨와 안쪽 글씨가 100% 동일한 크기로 렌더링됩니다.
      spans.add(TextSpan(
        text: kanji,
        style: isHigh ? highlightStyle : normalStyle,
        recognizer: _createRecognizer(kanji),
      ));

      cursor = m.end;
    }

    if (cursor < textSegment.length) {
      _addPlainHighlightedSpans(spans, textSegment.substring(cursor), ranges,
          textOffset + cursor, normalStyle, highlightStyle);
    }
  }

  void _addPlainHighlightedSpans(
    List<InlineSpan> spans,
    String textSegment,
    List<_TextRange> ranges,
    int textOffset,
    TextStyle normalStyle,
    TextStyle highlightStyle,
  ) {
    if (textSegment.isEmpty) return;

    int cursor = 0;
    int rangeIndex = 0;
    final textStart = textOffset;
    final textEnd = textOffset + textSegment.length;

    while (rangeIndex < ranges.length) {
      final range = ranges[rangeIndex];

      if (range.end <= textStart) {
        rangeIndex++;
        continue;
      }
      if (range.start >= textEnd) break;

      final localStart = (range.start - textStart).clamp(0, textSegment.length);
      final localEnd = (range.end - textStart).clamp(0, textSegment.length);

      if (cursor < localStart) {
        spans.add(TextSpan(
            text: textSegment.substring(cursor, localStart),
            style: normalStyle));
      }

      spans.add(TextSpan(
          text: textSegment.substring(localStart, localEnd),
          style: highlightStyle));

      cursor = localEnd;
      rangeIndex++;
    }

    if (cursor < textSegment.length) {
      spans.add(
          TextSpan(text: textSegment.substring(cursor), style: normalStyle));
    }
  }

  bool _isInRange(int start, int end, List<_TextRange> ranges) {
    for (final range in ranges) {
      int maxStart = start > range.start ? start : range.start;
      int minEnd = end < range.end ? end : range.end;
      if (maxStart < minEnd) return true;
    }
    return false;
  }
}

class _TextRange {
  _TextRange(this.start, this.end);
  final int start;
  final int end;
}
