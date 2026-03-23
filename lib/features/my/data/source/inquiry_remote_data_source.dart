import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

/// 문의사항 Supabase 통신 DataSource
@lazySingleton
class InquiryRemoteDataSource {
  /// 문의사항 전송
  Future<void> submitInquiry({
    required String userId,
    required String category,
    required String title,
    required String content,
    required Map<String, dynamic> deviceInfo,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('Supabase가 초기화되지 않았습니다.');
    }

    try {
      await client.from('user_inquiries').insert({
        'user_id': userId,
        'category': category,
        'title': title,
        'content': content,
        'device_info': deviceInfo,
        'status': 'pending',
      });

      Log.i('문의사항 전송 완료: $title');
    } catch (e, stackTrace) {
      Log.e('문의사항 전송 실패', errorObject: e, stackTrace: stackTrace);
      throw Exception('문의사항을 전송하는 중 오류가 발생했습니다.');
    }
  }

  /// 문의 내역 조회
  Future<List<Map<String, dynamic>>> getInquiries({
    required String userId,
  }) async {
    final client = SupabaseUtils.getClientOrNull();
    if (client == null) {
      throw Exception('Supabase가 초기화되지 않았습니다.');
    }

    try {
      final response = await client
          .from('user_inquiries')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      Log.e('문의 내역 조회 실패', errorObject: e, stackTrace: stackTrace);
      throw Exception('문의 내역을 불러오는 중 오류가 발생했습니다.');
    }
  }
}
