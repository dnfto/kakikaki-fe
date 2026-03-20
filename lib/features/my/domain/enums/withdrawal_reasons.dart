import 'package:flutter/widgets.dart';
import 'package:kakikaki/core/extension/extension.dart';

/// 탈퇴 사유
enum WithdrawalReason {
  lowUsage(code: 'low_usage'),
  otherApp(code: 'other_app'),
  lackOfFeatures(code: 'lack_of_features'),
  difficultToUse(code: 'difficult_to_use'),
  other(code: 'other');

  final String code;

  const WithdrawalReason({required this.code});
}

extension WithdrawalReasonL10n on WithdrawalReason {
  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case WithdrawalReason.lowUsage:
        return l10n.withdrawal_reason_low_usage;
      case WithdrawalReason.otherApp:
        return l10n.withdrawal_reason_other_app;
      case WithdrawalReason.lackOfFeatures:
        return l10n.withdrawal_reason_lack_of_features;
      case WithdrawalReason.difficultToUse:
        return l10n.withdrawal_reason_difficult_to_use;
      case WithdrawalReason.other:
        return l10n.withdrawal_reason_other;
    }
  }
}
