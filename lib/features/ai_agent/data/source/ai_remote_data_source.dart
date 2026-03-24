import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/features/ai_agent/domain/entity/chat_message.dart';

@lazySingleton
class AiRemoteDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> askAgent(String prompt, {String? userId}) async {
    try {
      final response = await _client.functions.invoke(
        'gemini-agent',
        body: {
          'message': prompt,
          if (userId != null) 'user_id': userId,
        },
      );

      if (response.data != null && response.data['reply'] != null) {
        return response.data['reply'] as String;
      }

      throw Exception('AI 응답이 올바르지 않습니다');
    } catch (e, stackTrace) {
      Log.e('AI 에이전트 호출 실패',
          name: 'AiRemoteDataSource', errorObject: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ChatMessage> saveChatMessage({
    required String userId,
    required String content,
    required bool isUser,
  }) async {
    try {
      final response = await _client
          .from('chat_history')
          .insert({
            'user_id': userId,
            'content': content,
            'is_user': isUser,
          })
          .select()
          .single();

      return ChatMessage(
        id: response['id'].toString(),
        content: response['content'].toString(),
        createdAt: DateTime.parse(response['created_at'].toString()),
        isUser: response['is_user'] as bool,
        role: response['is_user'] as bool ? 'user' : 'assistant',
      );
    } catch (e, stackTrace) {
      Log.e('채팅 내역 저장 실패',
          name: 'AiRemoteDataSource', errorObject: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<ChatMessage>> getChatHistory(String userId) async {
    try {
      final response = await _client
          .from('chat_history')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => ChatMessage(
                id: json['id'].toString(),
                content: json['content'].toString(),
                createdAt: DateTime.parse(json['created_at'].toString()),
                isUser: json['is_user'] as bool,
                role: json['is_user'] as bool ? 'user' : 'assistant',
              ))
          .toList();
    } catch (e, stackTrace) {
      Log.e('채팅 내역 불러오기 실패',
          name: 'AiRemoteDataSource', errorObject: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
