import 'package:injectable/injectable.dart';
import 'package:kakikaki/app/enums/user_role.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 사용자 정보 Supabase 통신 DataSource
@lazySingleton
class UserRemoteDataSource {
  /// 닉네임 업데이트
  Future<void> updateNickname({
    required String userId,
    required String newNickname,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('서버에 연결할 수 없습니다.');
    }

    try {
      await client
          .from('users')
          .update({'nickname': newNickname.trim()}).eq('id', userId);

      try {
        await client.auth.updateUser(
          UserAttributes(
            data: {'nickname': newNickname.trim()},
          ),
        );
      } catch (e) {
        Log.w('Auth 메타데이터 업데이트 실패 (무시됨): $e');
      }

      Log.i('닉네임 업데이트 완료: $newNickname');
    } catch (e, stackTrace) {
      Log.e(
        '닉네임 업데이트 실패',
        errorObject: e,
        stackTrace: stackTrace,
      );
      throw Exception('닉네임 변경 중 오류가 발생했습니다.');
    }
  }

  /// 회원 탈퇴 (Edge Function delete-account 호출)
  Future<void> deleteAccount({String? reason}) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) throw Exception('서버에 연결할 수 없습니다.');

    try {
      // 이제 수동 갱신이나 복잡한 헤더 주입이 전혀 필요 없습니다!
      final response = await client.functions.invoke(
        'delete-account',
        body: reason != null && reason.isNotEmpty ? {'reason': reason} : {},
      );

      final data = response.data;
      if (data is Map && (data['success'] != true)) {
        throw Exception(data['error'] ?? '알 수 없는 오류');
      }

      Log.i('회원 탈퇴 완료');
    } catch (e, stackTrace) {
      Log.e('회원 탈퇴 실패', errorObject: e, stackTrace: stackTrace);
      throw Exception('탈퇴 처리 중 오류가 발생했어요. 다시 시도해 주세요.');
    }
  }

  /// 프리미엄(구독) 상태 확인
  Future<bool> checkPremiumStatus({required String userId}) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      Log.w('Supabase 클라이언트가 없어 프리미엄 상태를 확인할 수 없습니다.');
      return false;
    }

    try {
      final response = await client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return false;
      final role = UserRole.fromDatabase(response['role']);
      return role.isPremium;
    } catch (e, stackTrace) {
      Log.e(
        '프리미엄 상태 확인 실패',
        name: 'UserRemoteDataSource',
        errorObject: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
