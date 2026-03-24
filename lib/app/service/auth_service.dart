import 'package:supabase_flutter/supabase_flutter.dart' hide User, LocalStorage;
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/domain/entity/user.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/storage/local_storage.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/router/routing.dart';

class AuthService {
  AuthService._();

  /// OAuth 메타데이터에 닉네임/이름이 없으면 null (DB nullable `nickname`과 동일하게 유지)
  static String? _resolvedNickname({
    required Map<String, dynamic>? userMetadata,
    String? customNickname,
  }) {
    if (customNickname != null && customNickname.trim().isNotEmpty) {
      return customNickname.trim();
    }
    final fromNickname = (userMetadata?['nickname'] as String?)?.trim();
    if (fromNickname != null && fromNickname.isNotEmpty) return fromNickname;
    final fromName = (userMetadata?['name'] as String?)?.trim();
    if (fromName != null && fromName.isNotEmpty) return fromName;
    return null;
  }

  static Future<void> processAuthSession(
    Session session,
    GlobalBloc bloc, {
    String? customNickname,
  }) async {
    try {
      final client = SupabaseUtils.getClientOrNull();
      if (client == null) return;

      final supabaseUser = session.user;
      final email = supabaseUser.email;

      final nickname = _resolvedNickname(
        userMetadata: supabaseUser.userMetadata,
        customNickname: customNickname,
      );
      final provider =
          supabaseUser.appMetadata['provider'] as String? ?? 'unknown';

      await client.from('users').update({
        'nickname': nickname,
      }).eq('id', supabaseUser.id);

      final appUser = User(
        id: supabaseUser.id,
        email: email,
        name: nickname,
      );

      bloc.add(GlobalEvent.changeUser(appUser));
      bloc.add(GlobalEvent.changeToken(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      ));

      if (provider == 'kakao') {
        bloc.add(const GlobalEvent.changeSocialType(SocialType.kakao));
      } else if (provider == 'apple') {
        bloc.add(const GlobalEvent.changeSocialType(SocialType.apple));
      }

      if (!bloc.state.isLoggedIn) {
        await bloc.stream.firstWhere((state) => state.isLoggedIn);
      }
      bloc.add(const GlobalEvent.checkPremiumStatus());
      Routing.router.go('/home');
    } catch (e, stackTrace) {
      await ErrorReporter.report(
        e,
        stackTrace: stackTrace,
        context: 'AuthService.processAuthSession',
      );
    }
  }

  static Future<void> restoreSessionIfNeeded(GlobalBloc bloc) async {
    try {
      final storage = await getIt.getAsync<LocalStorage>();
      final token = await storage.getEncrypted(AuthConstants.accessTokenKey);
      final refreshToken =
          await storage.getEncrypted(AuthConstants.refreshTokenKey);

      if (token == null ||
          token.isEmpty ||
          refreshToken == null ||
          refreshToken.isEmpty) {
        return;
      }

      final supabaseClient = SupabaseUtils.getClientOrNull();
      if (supabaseClient == null) return;

      final currentSession = supabaseClient.auth.currentSession;
      if (currentSession != null && bloc.state.user != null) return;

      final response = await supabaseClient.auth.refreshSession();

      if (response.session != null && response.user != null) {
        final user = response.user!;
        final email = user.email;
        if (email == null) return;

        final nickname = _resolvedNickname(userMetadata: user.userMetadata);
        final provider = user.appMetadata['provider'] as String? ?? 'unknown';

        final appUser = User(
          id: user.id,
          email: email,
          name: nickname,
        );

        bloc.add(GlobalEvent.changeUser(appUser));
        bloc.add(GlobalEvent.changeToken(
          accessToken: response.session!.accessToken,
          refreshToken: response.session!.refreshToken ?? '',
        ));

        if (provider == 'kakao') {
          bloc.add(const GlobalEvent.changeSocialType(SocialType.kakao));
        } else if (provider == 'apple') {
          bloc.add(const GlobalEvent.changeSocialType(SocialType.apple));
        }
      } else {
        await storage.deleteEncrypted(AuthConstants.accessTokenKey);
        await storage.deleteEncrypted(AuthConstants.refreshTokenKey);
        bloc.add(const GlobalEvent.signOut());
      }
    } catch (e, stackTrace) {
      await ErrorReporter.report(
        e,
        stackTrace: stackTrace,
        context: 'AuthService.restoreSessionIfNeeded',
      );
      try {
        final storage = await getIt.getAsync<LocalStorage>();
        await storage.deleteEncrypted(AuthConstants.accessTokenKey);
        await storage.deleteEncrypted(AuthConstants.refreshTokenKey);
        bloc.add(const GlobalEvent.signOut());
      } catch (cleanupError) {
        Log.e('AuthService.restoreSessionIfNeeded cleanupError: $cleanupError');
      }
    }
  }

  static Future<void> handleAuthCallback(GlobalBloc bloc) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) return;

    Session? session = client.auth.currentSession;
    if (session != null) {
      return AuthService.processAuthSession(session, bloc);
    }

    try {
      final authEvent = await client.auth.onAuthStateChange
          .firstWhere((event) => event.session != null)
          .timeout(const Duration(seconds: 5)); // 최대 5초 대기

      if (authEvent.session != null) {
        return AuthService.processAuthSession(authEvent.session!, bloc);
      }
    } catch (e) {
      Log.w('OAuth 콜백 - 세션 대기 시간(5초) 초과', name: 'AuthService');
    }
  }
}
