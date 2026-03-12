import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

/// URL에서 cursor 파라미터 값을 추출하는 유틸리티 클래스
class CursorUtils {
  /// URL에서 cursor 파라미터 값만 추출
  ///
  /// [url] - cursor 파라미터가 포함된 URL
  /// [paramName] - 추출할 파라미터 이름 (기본값: 'cursor')
  ///
  /// 예시:
  /// ```dart
  /// final cursor = CursorUtils.extractCursorFromUrl(
  ///   'https://api.example.com/data?cursor=cD01MA%3D%3D&page_size=10'
  /// );
  /// // 결과: 'cD01MA%3D%3D'
  /// ```
  static String? extractCursorFromUrl(String? url,
      {String paramName = 'cursor'}) {
    if (url == null) return null;

    try {
      final uri = Uri.parse(url);
      final cursor = uri.queryParameters[paramName];
      Log.d('[CursorUtils] URL에서 $paramName 추출: $url -> $cursor');
      return cursor;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'CursorUtils.extractCursorFromUrl',
      );
      return null;
    }
  }

  /// URL에서 next/previous cursor를 모두 추출
  ///
  /// [nextUrl] - next cursor가 포함된 URL
  /// [previousUrl] - previous cursor가 포함된 URL
  /// [paramName] - 추출할 파라미터 이름 (기본값: 'cursor')
  ///
  /// 예시:
  /// ```dart
  /// final cursors = CursorUtils.extractCursorsFromUrls(
  ///   nextUrl: 'https://api.example.com/data?cursor=next123',
  ///   previousUrl: 'https://api.example.com/data?cursor=prev456',
  /// );
  /// // 결과: {'next': 'next123', 'previous': 'prev456'}
  /// ```
  static Map<String, String?> extractCursorsFromUrls({
    String? nextUrl,
    String? previousUrl,
    String paramName = 'cursor',
  }) {
    return {
      'next': extractCursorFromUrl(nextUrl, paramName: paramName),
      'previous': extractCursorFromUrl(previousUrl, paramName: paramName),
    };
  }
}
