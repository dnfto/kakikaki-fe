import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/network/base_repository.dart';
import 'package:kakikaki/features/ai_agent/data/source/ai_remote_data_source.dart';
import 'package:kakikaki/features/ai_agent/domain/entity/chat_message.dart';
import 'package:kakikaki/features/ai_agent/domain/repository/ai_repository.dart';

@Injectable(as: AiRepository)
class AiRepositoryImpl extends BaseRepository implements AiRepository {
  AiRepositoryImpl(this._dataSource) : super('ai');

  final AiRemoteDataSource _dataSource;

  @override
  Future<String> askAgent(String prompt, {String? userId}) {
    return _dataSource.askAgent(prompt, userId: userId);
  }

  @override
  Future<ChatMessage> saveChatMessage({
    required String userId,
    required String content,
    required bool isUser,
  }) {
    return _dataSource.saveChatMessage(
      userId: userId,
      content: content,
      isUser: isUser,
    );
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String userId) {
    return _dataSource.getChatHistory(userId);
  }
}
