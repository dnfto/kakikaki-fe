import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/base/base.dart';
import 'package:kakikaki/features/ai_agent/domain/entity/chat_message.dart';
import 'package:kakikaki/features/ai_agent/domain/repository/ai_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_agent_bloc.freezed.dart';
part 'ai_agent_event.dart';
part 'ai_agent_state.dart';

@injectable
class AiAgentBloc extends BaseBloc<AiAgentEvent, AiAgentState> {
  final AiRepository _repository;

  AiAgentBloc(this._repository) : super(AiAgentState.initial()) {
    onWithoutAutoLoading<AiAgentStarted>(_onStarted);
    onWithoutAutoLoading<AiAgentMessageSent>(_onMessageSent);
    onWithoutAutoLoading<AiAgentLoadHistory>(_onLoadHistory);
  }

  Future<void> _onStarted(
    AiAgentStarted event,
    Emitter<AiAgentState> emit,
  ) async {
    if (event.userId != null) {
      add(AiAgentEvent.loadHistory(event.userId!));
    }
  }

  Future<void> _onMessageSent(
    AiAgentMessageSent event,
    Emitter<AiAgentState> emit,
  ) async {
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    // 낙관적 업데이트(Optimistic Update)용 임시 사용자 메시지
    final tempUserMessage = ChatMessage(
      id: tempId,
      content: event.message,
      createdAt: now,
      isUser: true,
      role: 'user',
    );

    await runBlocCatching(
      handleLoading: false, // 화면 전체 딤처리는 하지 않음
      handleToast: true, // 에러 시 BaseBloc의 토스트 활용
      doOnEventStart: () {
        // 로컬 화면에 유저 메시지 즉시 반영 + 로딩 스피너 on
        emit(state.copyWith(
          messages: [...state.messages, tempUserMessage],
          isGenerating: true,
        ));
      },
      action: () async {
        ChatMessage? finalUserMsg;
        String aiResponseText;

        if (event.userId != null) {
          // 유저 메시지 DB 저장과 AI API 호출을 병렬로 동시에 처리
          final results = await Future.wait([
            _repository.saveChatMessage(
              userId: event.userId!,
              content: event.message,
              isUser: true,
            ),
            _repository.askAgent(event.message, userId: event.userId),
          ]);

          finalUserMsg = results[0] as ChatMessage;
          aiResponseText = results[1] as String;
        } else {
          aiResponseText = await _repository.askAgent(event.message);
        }

        // AI 응답 저장
        ChatMessage aiMessage;
        if (event.userId != null) {
          aiMessage = await _repository.saveChatMessage(
            userId: event.userId!,
            content: aiResponseText,
            isUser: false,
          );
        } else {
          aiMessage = ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: aiResponseText,
            createdAt: DateTime.now(),
            isUser: false,
            role: 'assistant',
          );
        }

        return {'userMsg': finalUserMsg, 'aiMsg': aiMessage};
      },
      doOnSuccess: (result) {
        final finalUserMsg = result['userMsg'];
        final aiMessage = result['aiMsg'] as ChatMessage;

        // 임시 메시지를 진짜 DB 데이터로 갈아끼우고 AI 메시지 추가
        final updatedMessages = state.messages.map((m) {
          if (m.id == tempId && finalUserMsg != null) return finalUserMsg;
          return m;
        }).toList();

        emit(state.copyWith(
          messages: [...updatedMessages, aiMessage],
          isGenerating: false,
        ));
      },
      doOnError: (e) {
        emit(state.copyWith(isGenerating: false));
      },
    );
  }

  Future<void> _onLoadHistory(
    AiAgentLoadHistory event,
    Emitter<AiAgentState> emit,
  ) async {
    await runBlocCatching(
      handleLoading: true,
      handleError: false, // 조용히 로드
      action: () async {
        return await _repository.getChatHistory(event.userId);
      },
      doOnSuccess: (history) {
        emit(state.copyWith(messages: history));
      },
    );
  }
}
