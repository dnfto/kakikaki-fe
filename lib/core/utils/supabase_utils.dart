import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

/// Supabase 초기화 상태를 추적하고, 안전하게 [SupabaseClient]를 가져오기 위한 헬퍼.
class SupabaseUtils {
  static bool isInitialized = false;

  /// Supabase가 초기화된 경우에만 클라이언트를 반환합니다.
  /// - 플래그가 false여도, 이미 런타임에서 Supabase.instance가 살아있다면 한 번 더 확인합니다.
  /// - 완전히 초기화되지 않은 경우에는 null을 반환합니다.
  static SupabaseClient? getClientOrNull() {
    // 1차: 플래그 기준
    if (isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (e, stackTrace) {
        ErrorReporter.ignoreExpected(
          e,
          stackTrace: stackTrace,
          context: 'SupabaseUtils.getClientOrNull flag=true',
        );
        Log.w('SupabaseUtils: 플래그는 true지만 클라이언트 접근에 실패: $e',
            name: 'SupabaseUtils');
        return null;
      }
    }

    // 2차: 플래그는 false지만, 실제로는 이미 초기화돼 있을 수 있으니 한 번 더 확인
    try {
      final client = Supabase.instance.client;
      isInitialized = true;
      Log.i('SupabaseUtils: 런타임에서 Supabase가 이미 초기화되어 있어 플래그를 true로 수정',
          name: 'SupabaseUtils');
      return client;
    } catch (e, stackTrace) {
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'SupabaseUtils.getClientOrNull fallback',
      );
      // 진짜로 초기화 안 된 케이스
      Log.w('SupabaseUtils: Supabase가 아직 초기화되지 않음', name: 'SupabaseUtils');
      return null;
    }
  }
}
