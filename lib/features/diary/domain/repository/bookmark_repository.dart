import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';

/// 추천 표현 북마크 Repository 인터페이스
abstract class BookmarkRepository {
  /// 북마크된 추천 표현의 인덱스 목록 조회
  Future<Set<int>> fetchBookmarkedIndices({
    required String userId,
    required String diaryId,
    required List<DiaryRecommendationItem> recommendations,
  });

  /// 추천 표현 북마크 토글
  Future<void> toggleBookmark({
    required DiaryRecommendationItem item,
    required String userId,
    required String diaryId,
    required bool currentStatus,
  });
}
