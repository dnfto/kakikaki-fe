import 'package:kakikaki/features/diary/domain/model/diary_list_item.dart';

/// 일기 CRUD 관련 Repository 인터페이스
abstract class DiaryRepository {
  /// 사용자가 작성한 일기의 날짜 목록 조회
  Future<Set<DateTime>> getWrittenDates({required String userId});

  /// 특정 날짜의 일기 조회 (없으면 null)
  Future<DiaryListItem?> getDiaryByDate({
    required String userId,
    required DateTime date,
  });

  /// 일기 삭제
  Future<void> deleteDiary({
    required String diaryId,
    required String userId,
  });

  /// 일기 수정
  Future<void> updateDiary({
    required String diaryId,
    required String newContent,
  });
}
