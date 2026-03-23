import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/domain/repository/auth_repository.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/core/error/error_reporter.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/storage/local_storage.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

@Injectable(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<void> logout(SocialType? socialType) async {
    // 1. 소셜별 로그아웃
    try {
      if (socialType == SocialType.kakao) {
        try {
          await kakao.UserApi.instance.logout();
        } on kakao.KakaoAuthException catch (e, stackTrace) {
          // 사용자가 카카오 로그인을 이미 해제했거나, 토큰이 없는 경우 등은 무시
          ErrorReporter.ignoreExpected(
            e,
            stackTrace: stackTrace,
            context: 'Kakao logout no-op',
          );
        } catch (e, stackTrace) {
          // 기타 예외는 앱 로그아웃 흐름에는 영향 주지 않음
          ErrorReporter.ignoreExpected(
            e,
            stackTrace: stackTrace,
            context: 'Kakao logout failure',
          );
        }
      } else if (socialType == SocialType.apple) {
        // 현재 Apple 로그인은 테스트용 가짜 로그인이라 별도 SDK 로그아웃 처리 없음
      }
    } catch (e, stackTrace) {
      // 소셜 로그아웃 실패는 무시하고 계속 진행
      ErrorReporter.ignoreExpected(
        e,
        stackTrace: stackTrace,
        context: 'Social logout wrapper',
      );
    }

    // 2. Supabase Auth 세션 종료
    final client = SupabaseUtils.getClientOrNull();
    if (client != null) {
      try {
        // 로그아웃할 때는 기존 사용자에게 발급된 FCM 토큰을 null로 정리합니다.
        final userId = client.auth.currentUser?.id;
        if (userId != null) {
          try {
            await client.from('users').update({'fcm_token': null}).eq('id', userId);
          } catch (_) {
            // DB 정리 실패는 무시 (로그아웃 자체는 진행)
          }
        }

        // 로컬 캐시 토큰도 제거 -> 다음 로그인에서 동기화가 필요하면 다시 업데이트됩니다.
        try {
          await getIt<LocalStorage>().deleteEncrypted(AuthConstants.fcmTokenKey);
        } catch (_) {}

        await client.auth.signOut();
      } on AuthException catch (e, stackTrace) {
        // 이미 만료된 세션 등은 무시
        ErrorReporter.ignoreExpected(
          e,
          stackTrace: stackTrace,
          context: 'Supabase signOut expired session',
        );
      } catch (e, stackTrace) {
        // 기타 예외는 무시
        ErrorReporter.ignoreExpected(
          e,
          stackTrace: stackTrace,
          context: 'Supabase signOut unknown error',
        );
      }
    }
  }
}
