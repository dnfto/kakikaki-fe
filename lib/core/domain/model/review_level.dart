import 'package:kakikaki/l10n/app_localizations.dart';

enum ReviewLevel {
  again(0), // 다시 (틀림/암기 실패)
  hard(1), // 어려움 (간신히 맞힘)
  good(2), // 보통 (적당히 생각남)
  easy(3); // 쉬움 (완벽히 알고 있음)

  final int score;
  const ReviewLevel(this.score);

  String getLabel(AppLocalizations l10n) {
    switch (this) {
      case ReviewLevel.again:
        return l10n.review_level_again;
      case ReviewLevel.hard:
        return l10n.review_level_hard;
      case ReviewLevel.good:
        return l10n.review_level_good;
      case ReviewLevel.easy:
        return l10n.review_level_easy;
    }
  }
}
