import 'package:kakikaki/features/ai_agent/domain/entity/chat_message.dart';

/// AI 에이전트 관련 데이터를 관리하는 Repository 인터페이스
abstract class AiRepository {
  /// AI 에이전트에게 질문하고 응답을 받습니다
  Future<String> askAgent(String prompt, {String? userId});

  /// 채팅 메시지를 저장합니다
  Future<ChatMessage> saveChatMessage({
    required String userId,
    required String content,
    required bool isUser,
  });

  /// 사용자의 채팅 내역을 불러옵니다
  Future<List<ChatMessage>> getChatHistory(String userId);
}
