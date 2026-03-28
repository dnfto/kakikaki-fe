import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';
import 'package:kakikaki/features/ai_agent/domain/entity/chat_message.dart';
import 'package:kakikaki/features/ai_agent/presentation/bloc/ai_agent_bloc.dart';

/// AI 채팅 페이지
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState
    extends BaseScaffoldPageState<AiChatPage, AiAgentBloc, AiAgentState> {
  _AiChatPageState()
      : super(
          backgroundColor: Palette.white,
          horizontalMargin: 0,
          verticalMargin: 0,
        );

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    bloc.add(AiAgentEvent.started(userId: _getUserId()));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 상태(State)가 변할 때(메시지 추가 등) 스크롤을 알아서 내리도록 함
  @override
  void handleBlocStateListener(BuildContext context, AiAgentState state) {
    super.handleBlocStateListener(context, state);

    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  PreferredSizeWidget? get appBar {
    return AppBar(
      title: Text(
        'AI 채팅',
        style: context.h6_700Style,
      ),
    );
  }

  @override
  Widget buildPage(BuildContext context, AiAgentState state) {
    return Column(
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: state.messages.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.ai_chat_placeholder,
                          style: context.h6_400Style.copyWith(
                            color: Palette.gray50,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              if (state.isGenerating)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.ai_chat_thinking,
                        style:
                            context.h8_400Style.copyWith(color: Palette.gray50),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _buildInputArea(state),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isUser ? Palette.black : Palette.gray10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Palette.white : Palette.black,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(AiAgentState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.white,
        border: Border(
          top: BorderSide(color: Palette.gray20),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: !state.isGenerating,
              decoration: InputDecoration(
                hintText: context.l10n.ai_chat_message_hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: state.isGenerating ? null : _sendMessage,
            icon: const Icon(Icons.send),
            color: Palette.black,
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    bloc.add(
      AiAgentEvent.messageSent(
        message: message,
        userId: _getUserId(),
      ),
    );

    _messageController.clear();
  }

  String? _getUserId() {
    return getIt<GlobalBloc>().state.user?.id ??
        SupabaseUtils.getClientOrNull()?.auth.currentUser?.id;
  }
}
