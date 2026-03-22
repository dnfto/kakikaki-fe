import 'package:kakikaki/features/diary/domain/model/diary_recommendation_item.dart';

/// 일기 추천 단어/문법 Repository 인터페이스
abstract class DiaryRecommendationRepository {
  Future<List<DiaryRecommendationItem>> fetchRecommendationsByDiaryId({
    required String diaryId,
  });
}
