part of 'ai_agent_bloc.dart';

@freezed
class AiAgentEvent with _$AiAgentEvent {
  const factory AiAgentEvent.started({String? userId}) = AiAgentStarted;
  const factory AiAgentEvent.messageSent({
    required String message,
    String? userId,
  }) = AiAgentMessageSent;
  const factory AiAgentEvent.loadHistory(String userId) = AiAgentLoadHistory;
}
