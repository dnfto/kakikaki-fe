import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';

/// 일기 조회·삭제·수정 관련 원격 데이터 소스 (Supabase)
@lazySingleton
class DiaryRemoteDataSource {
  /// 사용자가 작성한 일기의 날짜 목록 조회
  Future<Set<DateTime>> getWrittenDates({required String userId}) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    final response = await client
        .from('diaries')
        .select('created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final writtenDates = <DateTime>{};
    for (final item in response as List) {
      try {
        final createdAtStr = item['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAtUtc = DateTime.parse(createdAtStr);
          final createdAtLocal = createdAtUtc.toLocal();
          final dateOnly = DateTime(
            createdAtLocal.year,
            createdAtLocal.month,
            createdAtLocal.day,
          );
          writtenDates.add(dateOnly);
        }
      } catch (_) {
        continue;
      }
    }
    return writtenDates;
  }

  /// 특정 날짜의 일기 조회
  /// 특정 날짜의 일기 조회
  Future<DiaryListItem?> getDiaryByDate({
    required String userId,
    required DateTime date,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    final dateOnly = DateTime(date.year, date.month, date.day);
    final localStartOfDay = dateOnly;
    final localEndOfDay = localStartOfDay.add(const Duration(days: 1));
    final utcStartOfDay = localStartOfDay.toUtc();
    final utcEndOfDay = localEndOfDay.toUtc();

    final response = await client
        .from('diaries')
        .select(
          'id, content, corrected_content, correction_notes, content_furigana, corrected_content_furigana, created_at, feedback_status',
        )
        .eq('user_id', userId)
        .gte('created_at', utcStartOfDay.toIso8601String())
        .lt('created_at', utcEndOfDay.toIso8601String())
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    // Supabase의 Map 응답을 DiaryListItem 객체로 변환해 리턴
    if (response != null) {
      return DiaryListItem.fromJson(response);
    }
    return null;
  }

  /// 일기 삭제
  Future<void> deleteDiary({
    required String diaryId,
    required String userId,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    try {
      await client.from('diaries').delete().eq('id', diaryId);

      final stats = await client
          .from('user_stats')
          .select('total_diaries_count')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();

      if (stats != null) {
        final currentCount = stats['total_diaries_count'] as int? ?? 0;
        if (currentCount > 0) {
          await client.from('user_stats').update({
            'total_diaries_count': currentCount - 1,
          }).eq('user_id', userId);
        }
      }
    } catch (e, stackTrace) {
      Log.e(
        '일기 삭제 실패',
        name: 'DiaryRemoteDataSource',
        errorObject: e,
        stackTrace: stackTrace,
      );
      throw Exception('일기를 삭제하지 못했습니다.');
    }
  }

  /// 일기 수정
  Future<void> updateDiary({
    required String diaryId,
    required String newContent,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버 초기화가 아직 완료되지 않았어요. 앱을 다시 실행해 주세요.');
    }

    try {
      await client.from('diaries').update({
        'content': newContent,
        'char_count': newContent.length,
        'corrected_content': null,
        'correction_notes': null,
        'content_furigana': null,
        'corrected_content_furigana': null,
      }).eq('id', diaryId);

      await client
          .from('user_recommendations')
          .delete()
          .eq('diary_id', diaryId);
    } catch (e, stackTrace) {
      Log.e(
        '일기 수정 실패',
        name: 'DiaryRemoteDataSource',
        errorObject: e,
        stackTrace: stackTrace,
      );
      throw Exception('일기를 수정하지 못했습니다.');
    }
  }
}
