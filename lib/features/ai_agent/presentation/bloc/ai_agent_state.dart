part of 'ai_agent_bloc.dart';

@freezed
class AiAgentState with _$AiAgentState {
  const factory AiAgentState({
    @Default(<ChatMessage>[]) List<ChatMessage> messages,
    @Default(false) bool isGenerating,
  }) = _AiAgentState;

  factory AiAgentState.initial() => const AiAgentState();
}
