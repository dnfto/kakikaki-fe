import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/features/home/data/dto/topic_dto.dart';

part 'diary_write_bloc.freezed.dart';
part 'diary_write_event.dart';
part 'diary_write_state.dart';

@injectable
class DiaryWriteBloc extends BaseBloc<DiaryWriteEvent, DiaryWriteState> {
  DiaryWriteBloc() : super(const DiaryWriteState()) {
    onWithoutAutoLoading<DiaryWriteTopicInitialized>((event, emit) {
      emit(state.copyWith(topic: event.topic, topicKo: event.topicKo));
    });
    onWithoutAutoLoading<DiaryWriteTopicChangeRequested>(
        _onTopicChangeRequested);
  }

  static const _topicsAssetPath = 'assets/data/topics_365.json';
  List<TopicDto> _topics = [];
  final Random _random = Random();

  Future<void> _onTopicChangeRequested(
    DiaryWriteTopicChangeRequested event,
    Emitter<DiaryWriteState> emit,
  ) async {
    // 1. 이미 데이터가 있으면 통신 없이 바로 랜덤 뽑기
    if (_topics.isNotEmpty) {
      _emitRandomTopic(emit);
      return;
    }

    // 2. 데이터가 없으면 로컬 json 파일을 읽어옴
    await runBlocCatching(
      handleLoading: false, // 로컬 파일이라 0.01초 컷이므로 화면 스피너 생략
      handleError: false, // 에러가 나더라도 조용히 무시 (화면 팝업 띄우지 않음)
      action: () async {
        final jsonString = await rootBundle.loadString(_topicsAssetPath);
        return jsonDecode(jsonString);
      },
      doOnSuccess: (decoded) {
        if (decoded is List) {
          _topics = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return TopicDto.fromJson(item);
                } catch (_) {
                  return null;
                }
              })
              .whereType<TopicDto>()
              .toList();
        }

        _emitRandomTopic(emit);
      },
    );
  }

  void _emitRandomTopic(Emitter<DiaryWriteState> emit) {
    if (_topics.isEmpty) return;
    final randomTopic = _topics[_random.nextInt(_topics.length)];
    emit(state.copyWith(topic: randomTopic.ja, topicKo: randomTopic.ko));
  }

  void setInitialTopic(String topic, String topicKo) =>
      add(DiaryWriteEvent.topicInitialized(topic, topicKo));
  void changeTopic() => add(const DiaryWriteEvent.topicChangeRequested());
}
