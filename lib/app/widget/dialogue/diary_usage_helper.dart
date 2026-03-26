import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/widget/dialogue/premium_dialog_hleper.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/context_extension.dart';
import 'package:kakikaki/core/utils/date_calendar_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

class DiaryUsageHelper {
  DiaryUsageHelper._();

  static Future<bool> checkCanWriteToday(BuildContext context,
      {bool isRetryFailed = false}) async {
    if (isRetryFailed) return true;

    final isPremium = getIt<GlobalBloc>().state.isPremium;
    if (isPremium) return true;

    final client = SupabaseUtils.getClientOrNull();
    final userId = getIt<GlobalBloc>().state.user?.id;
    if (client == null || userId == null) return false;

    try {
      final res = await client
          .from('user_stats')
          .select('daily_write_count, last_write_date')
          .eq('user_id', userId)
          .maybeSingle();

      if (res == null) return true;

      final lastWrite =
          DateCalendarUtils.parseTimestamptzToLocal(res['last_write_date']);
      final dailyCount = (res['daily_write_count'] as num?)?.toInt() ?? 0;

      // 💡 현재 폰의 실제 로컬 날짜와 비교
      final now = DateTime.now();

      if (lastWrite != null &&
          DateCalendarUtils.isSameLocalCalendarDay(lastWrite, now) &&
          dailyCount >= 2) {
        if (context.mounted) {
          await PremiumDialogHelper.showPremiumGuide(
            context,
            message: context.l10n.diary_usage_helper_message,
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint('Usage check error: $e');
    }

    return true;
  }
}
