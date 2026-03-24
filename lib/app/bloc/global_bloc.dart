import 'dart:async';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/storage/local_storage.dart';
import 'package:kakikaki/app/domain/entity/user.dart';
import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/data/repository/global_state_repository.dart';
import 'package:kakikaki/app/domain/repository/auth_repository.dart';
import 'package:kakikaki/features/my/domain/repository/user_repository.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/app/enums/primary_color_type.dart';
import 'package:kakikaki/app/enums/user_role.dart';
import 'package:kakikaki/features/home/presentation/bloc/home_bloc.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_bloc.dart';
import 'package:kakikaki/features/study/presentation/bloc/study_event.dart';
import 'package:kakikaki/features/vocabulary/presentation/bloc/list/vocabulary_list_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:kakikaki/core/utils/permission_request_handler.dart';

part 'global_state.dart';
part 'global_event.dart';
part 'global_bloc.freezed.dart';
part 'global_bloc.g.dart';

@singleton
class GlobalBloc extends BaseBloc<GlobalEvent, GlobalState> {
  LocalStorage get _storage => getIt<LocalStorage>();
  GlobalStateRepository get _repository => getIt<GlobalStateRepository>();
  supabase.RealtimeChannel? _userChannel;
  @override
  Future<void> close() {
    _userChannel?.unsubscribe();
    return super.close();
  }

  GlobalBloc._(super.initialState) {
    onWithoutAutoLoading<GlobalChangeLocale>(_onChangeLocale,
        transformer: sequential());
    onWithoutAutoLoading<GlobalChangeToken>(_onChangeToken,
        transformer: sequential());
    onWithoutAutoLoading<GlobalSignOut>(_onSignOut, transformer: sequential());
    onWithoutAutoLoading<GlobalLogoutRequested>(_onLogoutRequested,
        transformer: sequential());
    onWithoutAutoLoading<GlobalChangeUser>(_onChangeUser,
        transformer: sequential());
    onWithoutAutoLoading<GlobalUpdateUserNickname>(_onUpdateUserNickname,
        transformer: sequential());
    onWithoutAutoLoading<GlobalChangeSocialType>(_onChangeSocialType,
        transformer: sequential());
    onWithoutAutoLoading<GlobalChangeTheme>(_onChangeTheme,
        transformer: sequential());
    onWithoutAutoLoading<GlobalChangePrimaryColor>(_onChangePrimaryColor,
        transformer: sequential());
    onWithoutAutoLoading<GlobalCheckPremiumStatus>(_onCheckPremiumStatus,
        transformer: sequential());
    onWithoutAutoLoading<GlobalRefreshUserInfo>(_onRefreshUserInfo,
        transformer: sequential());
    onWithoutAutoLoading<GlobalPatchCoachMarks>(_onPatchCoachMarks,
        transformer: sequential());
    onWithoutAutoLoading<GlobalMarkLaunchPromoDialogShown>(
        _onMarkLaunchPromoDialogShown,
        transformer: sequential());
  }

  void _listenToUserRoleChanges(String userId) {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return;
    _userChannel?.unsubscribe();
    _userChannel = client
        .channel('public:users_role_status')
        .onPostgresChanges(
          event: supabase.PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: supabase.PostgresChangeFilter(
            type: supabase.PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) {
            final newRole = payload.newRecord['role'];
            final newTrialUsed = payload.newRecord['trial_used'];
            final currentIsPremium = state.isPremium;
            final currentTrialUsed = state.trialUsed;
            final isNowPremium = UserRole.fromDatabase(newRole).isPremium;
            final isNowTrialUsed = newTrialUsed == true;

            if (currentIsPremium != isNowPremium ||
                currentTrialUsed != isNowTrialUsed) {
              Log.i('실시간 상태 변경 감지! 즉시 조용히 새로고침합니다.');
              add(const GlobalEvent.refreshUserInfo());
            }
          },
        )
        .subscribe();
  }

  Future<void> _saveState(GlobalState state) async {
    await _repository.saveState(state);
  }

  Future<Map<String, bool>> _fetchOnboardingStatus(String userId) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      return {
        'home': false,
        'vocabulary': false,
        'study': false,
      };
    }
    try {
      final res = await client
          .from('users')
          .select(
              'onboarding_home_done, onboarding_vocabulary_done, onboarding_study_done')
          .eq('id', userId)
          .maybeSingle();
      if (res == null) {
        return {
          'home': false,
          'vocabulary': false,
          'study': false,
        };
      }
      return {
        'home': res['onboarding_home_done'] == true,
        'vocabulary': res['onboarding_vocabulary_done'] == true,
        'study': res['onboarding_study_done'] == true,
      };
    } catch (_) {
      return {
        'home': false,
        'vocabulary': false,
        'study': false,
      };
    }
  }

  FutureOr<void> _onChangeUser(
      GlobalChangeUser event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        if (event.user != null) {
          await _storage.saveItem(AuthConstants.userKey, event.user);
          _listenToUserRoleChanges(event.user!.id);
          await PermissionRequestHandler.syncFcmTokenToSupabase();
        } else {
          await _storage.saveItem(AuthConstants.userKey, null);
          _userChannel?.unsubscribe();
        }

        final u = event.user;
        final onboarding = u == null
            ? {
                'home': false,
                'vocabulary': false,
                'study': false,
              }
            : await _fetchOnboardingStatus(u.id);

        final newState = state.copyWith(
          user: u,
          coachMarkHomeDone: onboarding['home'] ?? false,
          coachMarkVocabularyDone: onboarding['vocabulary'] ?? false,
          coachMarkStudyDone: onboarding['study'] ?? false,
        );
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onMarkLaunchPromoDialogShown(
      GlobalMarkLaunchPromoDialogShown event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final uid = state.user?.id;
        if (uid == null) return;
        if (state.launchPromoShownUserIds.contains(uid)) return;
        final newState = state.copyWith(
          launchPromoShownUserIds: [...state.launchPromoShownUserIds, uid],
        );
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onPatchCoachMarks(
      GlobalPatchCoachMarks event, Emitter<GlobalState> emit) async {
    final userId = state.user?.id;
    if (userId == null) return;

    // 1) 즉시 반영
    final newState = state.copyWith(
      coachMarkHomeDone: event.homeDone ?? state.coachMarkHomeDone,
      coachMarkVocabularyDone:
          event.vocabularyDone ?? state.coachMarkVocabularyDone,
      coachMarkStudyDone: event.studyDone ?? state.coachMarkStudyDone,
    );
    emit(newState);
    await _saveState(newState);

    // 2) 백그라운드 DB 동기화
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        if (client == null) return;
        await client.from('users').update({
          if (event.homeDone != null) 'onboarding_home_done': event.homeDone,
          if (event.vocabularyDone != null)
            'onboarding_vocabulary_done': event.vocabularyDone,
          if (event.studyDone != null)
            'onboarding_study_done': event.studyDone,
        }).eq('id', userId);
      },
    );
  }

  FutureOr<void> _onUpdateUserNickname(
      GlobalUpdateUserNickname event, Emitter<GlobalState> emit) async {
    if (state.user != null) {
      final updatedUser = state.user!.copyWith(name: event.newNickname);
      await _storage.saveItem(AuthConstants.userKey, updatedUser);
      final newState = state.copyWith(user: updatedUser);
      emit(newState);
      await _saveState(newState);
    }
  }

  FutureOr<void> _onChangeSocialType(
      GlobalChangeSocialType event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final newState = state.copyWith(socialType: event.socialType);
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onChangeToken(
      GlobalChangeToken event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        if (event.accessToken != null && event.accessToken!.isNotEmpty) {
          await _storage.saveEncrypted(
              AuthConstants.accessTokenKey, event.accessToken!);
        } else {
          await _storage.deleteEncrypted(AuthConstants.accessTokenKey);
        }

        if (event.refreshToken != null && event.refreshToken!.isNotEmpty) {
          await _storage.saveEncrypted(
              AuthConstants.refreshTokenKey, event.refreshToken!);
        } else {
          await _storage.deleteEncrypted(AuthConstants.refreshTokenKey);
        }

        final newState = state.copyWith(
          isLoggedIn:
              event.accessToken != null && event.accessToken!.isNotEmpty,
        );
        emit(newState);
        await _saveState(newState);

        // 로그인 상태가 확정된 직후 프리미엄/구독 정보를 재동기화
        // (소셜 로그인 직후 users/subscriptions 반영 타이밍 이슈 보정)
        if (newState.isLoggedIn && newState.user != null) {
          add(const GlobalEvent.checkPremiumStatus());
          add(const GlobalEvent.refreshUserInfo());
        }
      },
    );
  }

  FutureOr<void> _onLogoutRequested(
      GlobalLogoutRequested event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: true,
      action: () async {
        getIt<HomeBloc>().add(const HomeEvent.resetOnLogout());
        getIt<VocabularyListBloc>()
            .add(const VocabularyListEvent.resetOnLogout());
        getIt<StudyBloc>().add(const StudyEvent.resetOnLogout());
        await getIt<AuthRepository>().logout(state.socialType);
      },
      doOnSuccess: (_) {
        add(const GlobalEvent.signOut());
      },
    );
  }

  FutureOr<void> _onSignOut(
      GlobalSignOut event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        final userId = client?.auth.currentUser?.id;
        if (client != null && userId != null) {
          try {
            await client
                .from('users')
                .update({'fcm_token': null}).eq('id', userId);
          } catch (_) {}
        }
        try {
          await _storage.deleteEncrypted(AuthConstants.fcmTokenKey);
        } catch (_) {}

        await _storage.saveItem(AuthConstants.userKey, null);
        await _storage.deleteEncrypted(AuthConstants.accessTokenKey);
        await _storage.deleteEncrypted(AuthConstants.refreshTokenKey);

        final newState = state.copyWith(
          isLoggedIn: false,
          user: null,
          socialType: null,
          isPremium: false,
          trialUsed: false,
          coachMarkHomeDone: false,
          coachMarkVocabularyDone: false,
          coachMarkStudyDone: false,
        );
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onChangeLocale(
      GlobalChangeLocale event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        FocusManager.instance.primaryFocus?.unfocus();
        final newState =
            state.copyWith(languageCode: event.locale.languageCode);
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onChangeTheme(
      GlobalChangeTheme event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final themeModeString = event.themeMode == ThemeMode.light
            ? 'light'
            : event.themeMode == ThemeMode.dark
                ? 'dark'
                : 'system';
        final newState = state.copyWith(themeMode: themeModeString);
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onChangePrimaryColor(
      GlobalChangePrimaryColor event, Emitter<GlobalState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      action: () async {
        final newState =
            state.copyWith(primaryColorType: event.primaryColorType.name);
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  FutureOr<void> _onCheckPremiumStatus(
      GlobalCheckPremiumStatus event, Emitter<GlobalState> emit) async {
    final userId = state.user?.id;
    if (userId == null || !state.isLoggedIn) return;

    await runBlocCatching(
      handleLoading: false,
      handleError: false,
      action: () async {
        final isRolePremium =
            await getIt<UserRepository>().checkPremiumStatus(userId: userId);

        bool trialUsed = state.trialUsed;
        bool hasActiveSubscription = false;
        bool onboardingHomeDone = state.coachMarkHomeDone;
        bool onboardingVocabularyDone = state.coachMarkVocabularyDone;
        bool onboardingStudyDone = state.coachMarkStudyDone;

        final client = SupabaseUtils.getClientOrNull();
        if (client != null) {
          final res = await client
              .from('users')
              .select(
                  'trial_used, onboarding_home_done, onboarding_vocabulary_done, onboarding_study_done')
              .eq('id', userId)
              .maybeSingle();
          if (res != null) {
            trialUsed = res['trial_used'] == true;
            onboardingHomeDone = res['onboarding_home_done'] == true;
            onboardingVocabularyDone = res['onboarding_vocabulary_done'] == true;
            onboardingStudyDone = res['onboarding_study_done'] == true;
          }

          final nowStr = DateTime.now().toUtc().toIso8601String();
          final subRes = await client
              .from('subscriptions')
              .select('id')
              .eq('user_id', userId)
              .eq('status', 'active')
              .gte('end_date', nowStr)
              .maybeSingle();

          if (subRes != null) hasActiveSubscription = true;
        }
        final finalIsPremium = isRolePremium || hasActiveSubscription;
        return {
          'isPremium': finalIsPremium,
          'trialUsed': trialUsed,
          'onboardingHomeDone': onboardingHomeDone,
          'onboardingVocabularyDone': onboardingVocabularyDone,
          'onboardingStudyDone': onboardingStudyDone,
        };
      },
      doOnSuccess: (result) async {
        final isPremium = result['isPremium'] as bool;
        final trialUsed = result['trialUsed'] as bool;
        final onboardingHomeDone = result['onboardingHomeDone'] as bool;
        final onboardingVocabularyDone =
            result['onboardingVocabularyDone'] as bool;
        final onboardingStudyDone = result['onboardingStudyDone'] as bool;

        if (state.isPremium != isPremium ||
            state.trialUsed != trialUsed ||
            state.coachMarkHomeDone != onboardingHomeDone ||
            state.coachMarkVocabularyDone != onboardingVocabularyDone ||
            state.coachMarkStudyDone != onboardingStudyDone) {
          final newState = state.copyWith(
            isPremium: isPremium,
            trialUsed: trialUsed,
            coachMarkHomeDone: onboardingHomeDone,
            coachMarkVocabularyDone: onboardingVocabularyDone,
            coachMarkStudyDone: onboardingStudyDone,
          );
          emit(newState);
          await _saveState(newState);
        }
      },
    );
  }

  FutureOr<void> _onRefreshUserInfo(
      GlobalRefreshUserInfo event, Emitter<GlobalState> emit) async {
    final userId = state.user?.id;
    if (userId == null || !state.isLoggedIn) return;

    await runBlocCatching(
      handleLoading: false,
      handleToast: false,
      action: () async {
        final isRolePremium =
            await getIt<UserRepository>().checkPremiumStatus(userId: userId);

        bool trialUsed = state.trialUsed;
        bool hasActiveSubscription = false;
        bool onboardingHomeDone = state.coachMarkHomeDone;
        bool onboardingVocabularyDone = state.coachMarkVocabularyDone;
        bool onboardingStudyDone = state.coachMarkStudyDone;

        final client = SupabaseUtils.getClientOrNull();
        if (client != null) {
          final res = await client
              .from('users')
              .select(
                  'trial_used, onboarding_home_done, onboarding_vocabulary_done, onboarding_study_done')
              .eq('id', userId)
              .maybeSingle();
          if (res != null) {
            trialUsed = res['trial_used'] == true;
            onboardingHomeDone = res['onboarding_home_done'] == true;
            onboardingVocabularyDone = res['onboarding_vocabulary_done'] == true;
            onboardingStudyDone = res['onboarding_study_done'] == true;
          }

          final nowStr = DateTime.now().toUtc().toIso8601String();
          final subRes = await client
              .from('subscriptions')
              .select('id')
              .eq('user_id', userId)
              .eq('status', 'active')
              .gte('end_date', nowStr)
              .maybeSingle();

          if (subRes != null) hasActiveSubscription = true;
        }

        final finalIsPremium = isRolePremium || hasActiveSubscription;

        final newState = state.copyWith(
          isPremium: finalIsPremium,
          trialUsed: trialUsed,
          coachMarkHomeDone: onboardingHomeDone,
          coachMarkVocabularyDone: onboardingVocabularyDone,
          coachMarkStudyDone: onboardingStudyDone,
        );
        emit(newState);
        await _saveState(newState);
      },
    );
  }

  @factoryMethod
  static Future<GlobalBloc> create() async {
    try {
      final storage = await getIt.getAsync<LocalStorage>();
      final repository = getIt.get<GlobalStateRepository>();
      final token = await storage.getEncrypted(AuthConstants.accessTokenKey);
      final isLoggedIn = token != null && token.isNotEmpty;

      final initialState = await repository.loadInitialState(isLoggedIn);
      final bloc = GlobalBloc._(initialState);

      if (isLoggedIn) {
        bloc.add(const GlobalEvent.checkPremiumStatus());
        bloc.add(const GlobalEvent.refreshUserInfo());
        if (initialState.user?.id != null) {
          bloc._listenToUserRoleChanges(initialState.user!.id);
        }
      }
      return bloc;
    } catch (e, stackTrace) {
      await ErrorReporter.report(e,
          stackTrace: stackTrace, context: 'GlobalBloc.create');
      return Future.error('GlobalBloc 초기화 실패: $e', stackTrace);
    }
  }
}
