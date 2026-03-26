import 'package:flutter/material.dart';
import 'package:xml/xml.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/image/common_icon.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/kanji_db_helper.dart';

class KanjiPracticeWidget extends StatefulWidget {
  const KanjiPracticeWidget({
    super.key,
    required this.kanji,
    this.onClose,
  });

  final String kanji;
  final VoidCallback? onClose;

  @override
  State<KanjiPracticeWidget> createState() => _KanjiPracticeWidgetState();
}

class _KanjiPracticeWidgetState extends State<KanjiPracticeWidget>
    with TickerProviderStateMixin {
  List<Path> _kanjiPaths = [];
  List<_StrokeNumberMarker> _strokeMarkers = [];
  int _totalStrokes = 0;
  int _currentStroke = 0;
  bool _isPlaying = false;
  bool _isLoadingKanji = false;
  String? _kanjiError;
  AnimationController? _animationController;
  final List<List<Offset>> _strokes = [];
  List<Offset> _current = [];
  String _currentKanji = ''; // 실제로 로드 중인 한자 (첫 글자만)
  static final Map<String, List<Path>> _pathCache = {};
  static final Map<String, List<_StrokeNumberMarker>> _markerCache = {};

  @override
  void initState() {
    super.initState();
    // 여러 글자가 전달될 경우 첫 번째 한자만 추출
    _currentKanji = _extractFirstKanji(widget.kanji);
    _loadKanjiPaths(_currentKanji);
  }

  /// 여러 글자 중 첫 번째 한자만 추출
  String _extractFirstKanji(String input) {
    final kanjiRegex = RegExp(r'[\u4e00-\u9faf]');
    final match = kanjiRegex.firstMatch(input);
    return match?.group(0) ?? input;
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  Future<void> _loadKanjiPaths(String kanji) async {
    if (_pathCache.containsKey(kanji)) {
      setState(() {
        _kanjiPaths = _pathCache[kanji]!;
        _strokeMarkers = _markerCache[kanji] ?? const [];
        _totalStrokes = _kanjiPaths.length;
        _isLoadingKanji = false;
      });
      _initAnimation();
      // _animationController?.forward();
      // _animationController?.repeat();
      // setState(() => _isPlaying = true);
      // 자동 재생 금지: 로드 후에는 정지 상태 유지
      _animationController?.reset();
      setState(() {
        _currentStroke = _totalStrokes > 0 ? 1 : 0;
        _isPlaying = false;
      });
      return;
    }

    setState(() {
      _isLoadingKanji = true;
      _kanjiError = null;
    });

    try {
      final svgData = await KanjiDbHelper.getSvgData(kanji);
      if (svgData == null || svgData.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingKanji = false;
          _kanjiError = context.l10n.kanji_error_no_data(kanji);
        });
        return;
      }
      final document = XmlDocument.parse(svgData);
      final paths = <MapEntry<int, Path>>[];
      final markers = <_StrokeNumberMarker>[];

      final strokeIdRegex = RegExp(r'-s(\d+)$');
      for (final pathElement in document.findAllElements('path')) {
        final idAttr = pathElement.getAttribute('id');
        final dAttr = pathElement.getAttribute('d');
        if (idAttr == null || dAttr == null) continue;

        final match = strokeIdRegex.firstMatch(idAttr);
        if (match == null) continue;

        final strokeNum = int.tryParse(match.group(1)!);
        if (strokeNum == null) continue;

        try {
          final path = _parsePathData(dAttr);
          paths.add(MapEntry(strokeNum, path));
        } catch (e, stackTrace) {
          ErrorReporter.ignoreExpected(e,
              stackTrace: stackTrace, context: 'Kanji path parse failure');
        }
      }

      final matrixRegex = RegExp(
          r'matrix\(\s*[-\d.]+\s+[-\d.]+\s+[-\d.]+\s+[-\d.]+\s+([-\d.]+)\s+([-\d.]+)\s*\)');
      for (final textElement in document.findAllElements('text')) {
        final number = int.tryParse(textElement.innerText.trim());
        if (number == null) continue;

        double? x, y;
        final transform = textElement.getAttribute('transform') ?? '';
        final m = matrixRegex.firstMatch(transform);
        if (m != null) {
          x = double.tryParse(m.group(1)!);
          y = double.tryParse(m.group(2)!);
        } else {
          x = double.tryParse(textElement.getAttribute('x') ?? '');
          y = double.tryParse(textElement.getAttribute('y') ?? '');
        }

        if (x != null && y != null) {
          markers
              .add(_StrokeNumberMarker(number: number, position: Offset(x, y)));
        }
      }

      paths.sort((a, b) => a.key.compareTo(b.key));
      markers.sort((a, b) => a.number.compareTo(b.number));
      final sortedPaths = paths.map((e) => e.value).toList();

      _pathCache[kanji] = sortedPaths;
      _markerCache[kanji] = markers;

      if (!mounted) return;
      setState(() {
        _kanjiPaths = sortedPaths;
        _strokeMarkers = markers;
        _totalStrokes = sortedPaths.length;
        _currentStroke = sortedPaths.isNotEmpty ? 1 : 0;
        _isLoadingKanji = false;
      });
      _initAnimation();
      // _animationController?.forward();
      // _animationController?.repeat();
      // setState(() => _isPlaying = true);
      // 자동 재생 금지: 로드 후에는 정지 상태 유지
      _animationController?.reset();
      setState(() => _isPlaying = false);
    } catch (e, stackTrace) {
      await ErrorReporter.report(e,
          stackTrace: stackTrace, context: 'Kanji SVG parsing failure');
      if (!mounted) return;
      setState(() {
        _isLoadingKanji = false;
        // 에러 메시지에서 한자 정보 포함
        _kanjiError = e.toString().contains('DB에 해당 한자')
            ? context.l10n.kanji_error_no_data(kanji)
            : context.l10n.kanji_error_load_failed(kanji);
      });
    }
  }

  Path _parsePathData(String d) {
    final path = Path();

    final isCommandRegEx = RegExp(r'^[A-Za-z]$');
    final tokenReg = RegExp(r'[MmLlHhVvCcQqZz]|-?\d*\.?\d+');

    final tokens = tokenReg.allMatches(d).map((m) => m.group(0)!).toList();

    int i = 0;
    String cmd = '';
    double x = 0, y = 0;
    double startX = 0, startY = 0;

    double nextNum() {
      if (i >= tokens.length) return 0.0;
      final token = tokens[i];
      if (isCommandRegEx.hasMatch(token)) return 0.0;
      return double.tryParse(token) ?? 0.0;
    }

    void advance() {
      if (i < tokens.length && !isCommandRegEx.hasMatch(tokens[i])) {
        i++;
      }
    }

    // 💡 최후의 안전장치: 어떤 경우에도 무한 루프를 막아냅니다.
    int loopGuard = 0;

    while (i < tokens.length) {
      if (loopGuard++ > 10000) return path; // 루프가 비정상적으로 길어지면 강제 탈출!

      final t = tokens[i];
      if (isCommandRegEx.hasMatch(t)) {
        cmd = t;
        i++;
      }

      if (cmd.isEmpty) {
        i++;
        continue;
      }

      int prevI = i; // 💡 현재 인덱스 기억

      switch (cmd) {
        case 'M':
          // 💡 break 대신 return path로 즉시 탈출하여 무한 루프 원천 차단
          if (i + 1 >= tokens.length) return path;
          x = nextNum();
          advance();
          y = nextNum();
          advance();
          path.moveTo(x, y);
          startX = x;
          startY = y;
          cmd = 'L';
          break;
        case 'm':
          if (i + 1 >= tokens.length) return path;
          x += nextNum();
          advance();
          y += nextNum();
          advance();
          path.moveTo(x, y);
          startX = x;
          startY = y;
          cmd = 'l';
          break;
        case 'L':
          if (i + 1 >= tokens.length) return path;
          x = nextNum();
          advance();
          y = nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'l':
          if (i + 1 >= tokens.length) return path;
          x += nextNum();
          advance();
          y += nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'H':
          if (i >= tokens.length) return path;
          x = nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'h':
          if (i >= tokens.length) return path;
          x += nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'V':
          if (i >= tokens.length) return path;
          y = nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'v':
          if (i >= tokens.length) return path;
          y += nextNum();
          advance();
          path.lineTo(x, y);
          break;
        case 'C':
          if (i + 5 >= tokens.length) return path;
          final x1 = nextNum();
          advance();
          final y1 = nextNum();
          advance();
          final x2 = nextNum();
          advance();
          final y2 = nextNum();
          advance();
          x = nextNum();
          advance();
          y = nextNum();
          advance();
          path.cubicTo(x1, y1, x2, y2, x, y);
          break;
        case 'c':
          if (i + 5 >= tokens.length) return path;
          final cx1 = x + nextNum();
          advance();
          final cy1 = y + nextNum();
          advance();
          final cx2 = x + nextNum();
          advance();
          final cy2 = y + nextNum();
          advance();
          x += nextNum();
          advance();
          y += nextNum();
          advance();
          path.cubicTo(cx1, cy1, cx2, cy2, x, y);
          break;
        case 'Q':
          if (i + 3 >= tokens.length) return path;
          final qx1 = nextNum();
          advance();
          final qy1 = nextNum();
          advance();
          x = nextNum();
          advance();
          y = nextNum();
          advance();
          path.quadraticBezierTo(qx1, qy1, x, y);
          break;
        case 'q':
          if (i + 3 >= tokens.length) return path;
          final rqx1 = x + nextNum();
          advance();
          final rqy1 = y + nextNum();
          advance();
          x += nextNum();
          advance();
          y += nextNum();
          advance();
          path.quadraticBezierTo(rqx1, rqy1, x, y);
          break;
        case 'Z':
        case 'z':
          path.close();
          x = startX;
          y = startY;
          cmd = ''; // 💡 Z루프 탈출구: 명령어 리셋
          break;
        default:
          i++;
      }

      // 💡 만약 코드가 꼬여서 인덱스(i)가 1칸도 전진하지 못했다면 강제로 전진!
      if (i == prevI) {
        i++;
      }
    }

    return path;
  }

  void _initAnimation() {
    _animationController?.dispose();
    if (_totalStrokes == 0) return;

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalStrokes * 400),
    );

    _animationController!.addListener(() {
      if (!mounted) return;
      final progress = _animationController!.value;
      final strokeIndex = (progress * _totalStrokes).floor();
      final newStroke = (strokeIndex + 1).clamp(1, _totalStrokes);
      if (_currentStroke != newStroke) {
        setState(() => _currentStroke = newStroke);
      }
    });

    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isPlaying) {
        _animationController!.repeat();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: context.screenHeight * 0.33,
          decoration: BoxDecoration(
            color: Palette.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Palette.gray30),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onVerticalDragStart: (_) {},
                onHorizontalDragStart: (_) {},
                onTapDown: (_) {},
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) {
                    if (event.localPosition.dx < 0 ||
                        event.localPosition.dx > constraints.maxWidth ||
                        event.localPosition.dy < 0 ||
                        event.localPosition.dy > constraints.maxHeight) {
                      return;
                    }
                    setState(() => _current = [event.localPosition]);
                  },
                  onPointerMove: (event) {
                    final clampedX =
                        event.localPosition.dx.clamp(0.0, constraints.maxWidth);
                    final clampedY = event.localPosition.dy
                        .clamp(0.0, constraints.maxHeight);
                    setState(() => _current.add(Offset(clampedX, clampedY)));
                  },
                  onPointerUp: (_) {
                    if (_current.isEmpty) return;
                    setState(() {
                      _strokes.add(_current);
                      _current = [];
                    });
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(child: _buildKanjiLayer(context)),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _PracticePainter(
                            strokes: _strokes,
                            current: _current,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: _animationController == null
                    ? null
                    : () {
                        if (_isPlaying) {
                          _animationController!.stop();
                          setState(() => _isPlaying = false);
                        } else {
                          if (_animationController!.value >= 0.999) {
                            _animationController!.reset();
                          }
                          _animationController!.forward();
                          _animationController!.repeat();
                          setState(() => _isPlaying = true);
                        }
                      },
                iconSize: 28,
                color: context.palette.primary,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _animationController == null
                    ? null
                    : () {
                        _animationController!.reset();
                        setState(() {
                          _currentStroke = _totalStrokes > 0 ? 1 : 0;
                          _isPlaying = false;
                        });
                      },
                iconSize: 24,
                color: Palette.gray60,
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: CommonIcon(IconPath.eraser,
                    colorFilter: CommonIcon.fillColor(Palette.gray60)),
                onPressed: () => setState(() {
                  _strokes.clear();
                  _current = [];
                }),
                iconSize: 24,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKanjiLayer(BuildContext context) {
    if (_isLoadingKanji) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_kanjiError != null ||
        _kanjiPaths.isEmpty ||
        _animationController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _currentKanji,
                style: context.h2_700Style.copyWith(color: Palette.gray20),
                textAlign: TextAlign.center,
              ),
              if (widget.kanji != _currentKanji) ...[
                const SizedBox(height: 4),
                Text(
                  '(전체: ${widget.kanji})',
                  style: context.h8_400Style.copyWith(color: Palette.gray40),
                  textAlign: TextAlign.center,
                ),
              ],
              if (_kanjiError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _kanjiError!,
                  style: context.h7_400Style.copyWith(color: Palette.gray50),
                  textAlign: TextAlign.center,
                ),
              ]
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animationController!,
      builder: (context, child) {
        return CustomPaint(
          painter: _KanjiAnimationPainter(
            paths: _kanjiPaths,
            strokeMarkers: _strokeMarkers,
            progress: _animationController!.value,
            totalStrokes: _totalStrokes,
            primaryColor: context.palette.primary,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _KanjiAnimationPainter extends CustomPainter {
  _KanjiAnimationPainter({
    required this.paths,
    required this.strokeMarkers,
    required this.progress,
    required this.totalStrokes,
    required this.primaryColor,
  });

  final List<Path> paths;
  final List<_StrokeNumberMarker> strokeMarkers;
  final double progress;
  final int totalStrokes;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (paths.isEmpty) return;

    final bounds = _getBounds(paths);
    final scale = _calculateScale(bounds, size);
    final offset = _calculateOffset(bounds, size, scale);

    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.scale(scale);

    final currentStrokeIndex = (progress * totalStrokes).floor();
    final currentStrokeProgress =
        (progress * totalStrokes) - currentStrokeIndex;

    final completedPaint = Paint()
      ..color = primaryColor.withExactOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < currentStrokeIndex && i < paths.length; i++) {
      canvas.drawPath(paths[i], completedPaint);
    }

    if (currentStrokeIndex < paths.length && currentStrokeProgress > 0) {
      final currentPath = paths[currentStrokeIndex];
      final metrics = currentPath.computeMetrics().firstOrNull;
      if (metrics != null) {
        final currentPaint = Paint()
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final pathToDraw = Path();
        pathToDraw.addPath(currentPath, Offset.zero);
        final pathMetrics = pathToDraw.computeMetrics().firstOrNull;
        if (pathMetrics != null) {
          final length = pathMetrics.length;
          final extractedPath =
              pathMetrics.extractPath(0, length * currentStrokeProgress);
          canvas.drawPath(extractedPath, currentPaint);
        }
      }
    }

    final hintPaint = Paint()
      ..color = primaryColor.withExactOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (int i = currentStrokeIndex; i < paths.length; i++) {
      canvas.drawPath(paths[i], hintPaint);
    }

    final numberStyle =
        Fonts.h9_500.copyWith(color: primaryColor.withExactOpacity(0.85));
    for (final marker in strokeMarkers) {
      final tp = TextPainter(
        text: TextSpan(text: marker.number.toString(), style: numberStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, marker.position);
    }

    canvas.restore();
  }

  Rect _getBounds(List<Path> paths) {
    if (paths.isEmpty) return Rect.zero;
    Rect? bounds;
    for (final path in paths) {
      final pathBounds = path.getBounds();
      bounds = bounds == null ? pathBounds : bounds.expandToInclude(pathBounds);
    }
    return bounds ?? Rect.zero;
  }

  double _calculateScale(Rect bounds, Size canvasSize) {
    if (bounds.isEmpty) return 1.0;
    final padding = 20.0;
    final availableWidth = canvasSize.width - padding * 2;
    final availableHeight = canvasSize.height - padding * 2;
    final scaleX = availableWidth / bounds.width;
    final scaleY = availableHeight / bounds.height;
    return (scaleX < scaleY ? scaleX : scaleY).clamp(0.1, 2.0);
  }

  Offset _calculateOffset(Rect bounds, Size canvasSize, double scale) {
    if (bounds.isEmpty) return Offset.zero;
    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;
    final offsetX = (canvasSize.width - scaledWidth) / 2 - bounds.left * scale;
    final offsetY = (canvasSize.height - scaledHeight) / 2 - bounds.top * scale;
    return Offset(offsetX, offsetY);
  }

  @override
  bool shouldRepaint(covariant _KanjiAnimationPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.paths != paths ||
        oldDelegate.strokeMarkers != strokeMarkers ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.totalStrokes != totalStrokes;
  }
}

class _PracticePainter extends CustomPainter {
  _PracticePainter({
    required this.strokes,
    required this.current,
  });

  final List<List<Offset>> strokes;
  final List<Offset> current;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }
    _drawStroke(canvas, current, paint);
  }

  void _drawStroke(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PracticePainter oldDelegate) {
    return oldDelegate.strokes != strokes || oldDelegate.current != current;
  }
}

class _StrokeNumberMarker {
  const _StrokeNumberMarker({required this.number, required this.position});
  final int number;
  final Offset position;
}
