import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/home/presentation/bloc/home_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 앱 전역에서 일기 피드백 완료/실패를 감지해 스낵바를 표시한다.
class DiaryFeedbackRealtimeNotificationService {
  DiaryFeedbackRealtimeNotificationService._();

  static final DiaryFeedbackRealtimeNotificationService instance =
      DiaryFeedbackRealtimeNotificationService._();

  bool _started = false;
  String? _subscribedUserId;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authStateSub;

  void start({
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) {
    _messengerKey = messengerKey;
    if (_started) return;
    _started = true;

    _bindRealtimeChannelForCurrentUser();

    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return;

    _authStateSub = client.auth.onAuthStateChange.listen((_) {
      _bindRealtimeChannelForCurrentUser();
    });
  }

  void stop() {
    _authStateSub?.cancel();
    _authStateSub = null;
    _channel?.unsubscribe();
    _channel = null;
    _subscribedUserId = null;
    _started = false;
  }

  void _bindRealtimeChannelForCurrentUser() {
    final client = SupabaseUtils.getClientOrNull();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null || userId.isEmpty) {
      _channel?.unsubscribe();
      _channel = null;
      _subscribedUserId = null;
      return;
    }

    if (_subscribedUserId == userId && _channel != null) return;

    _channel?.unsubscribe();
    _subscribedUserId = userId;

    _channel = client
        .channel('public:diaries_global_feedback')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'diaries',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final status = payload.newRecord['feedback_status']?.toString();
            if (status == 'completed' || status == 'failed') {
              final l10n =
                  lookupAppLocalizations(getIt<GlobalBloc>().state.locale);
              if (status == 'completed') {
                _showSnackBar(
                  SnackBar(
                    content: Text(l10n.diary_feedback_realtime_completed),
                    backgroundColor: Palette.black,
                    duration: const Duration(seconds: 4),
                  ),
                );
              } else {
                _showSnackBar(
                  SnackBar(
                    content: Text(l10n.diary_feedback_realtime_failed),
                    backgroundColor: Palette.black,
                  ),
                );
              }
            }

            // 어떤 화면이든 홈 상태도 최신으로 맞춰주기
            try {
              final homeBloc = getIt<HomeBloc>();
              homeBloc.add(const HomeEvent.refreshDiary());
            } catch (_) {
              // HomeBloc이 아직 초기화되지 않은 경우는 무시
            }
          },
        )
        .subscribe();
  }

  void _showSnackBar(SnackBar snackBar) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snackBar);
  }
}
