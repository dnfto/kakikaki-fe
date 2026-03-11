import 'package:bloc_concurrency/bloc_concurrency.dart' as concurrency;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';

/// BLoC 라이브러리의 이벤트 처리 방식을 확장하기 위해 bloc_concurrency 패키지를 활용
// bloc_concurrency: BLoC의 이벤트 처리 방식을 제어할 수 있는 유틸리티를 제공
///
/// BLoC 이벤트 핸들러에 다양한 이벤트 변환기를 지정해 이벤트 처리를 유연하게 제어
mixin EventTransformerMixin<E, S> on BaseBlocDelegate<E, S> {
  // <E, S>: E는 이벤트 타입, S는 상태 타입
  // on BaseBlocDelegate<E, S>: 이 mixin은 BaseBlocDelegate를 상속하는 클래스에서만 사용 가능

  /// concurrent(): 이벤트를 병렬로 처리
  /// 이벤트가 동시에 실행되므로 성능은 향상되지만, 이벤트 순서는 보장하지 않음.
  EventTransformer<Event> concurrent<Event>() =>
      concurrency.concurrent<Event>();

  /// sequential(): 이벤트를 순차적으로 처리
  /// 이전 이벤트 처리가 완료될 때까지 다음 이벤트 처리가 시작되지 않는다.
  EventTransformer<Event> sequential<Event>() =>
      concurrency.sequential<Event>();

  /// droppable(): 이벤트 처리 중 중복 이벤트 무시
  /// 이벤트 처리 중에 들어온 이벤트가 무시되므로 리소스 절약 가능
  EventTransformer<Event> droppable<Event>() => concurrency.droppable<Event>();

  /// restartable(): 이전 작업을 취소하고 최신 이벤트만 처리
  EventTransformer<Event> restartable<Event>() =>
      concurrency.restartable<Event>();

  /// distinct(): 중복 이벤트 방지. 이벤트 중복 발생 시 무시
  EventTransformer<Event> distinct<Event>() =>
      (Stream<Event> events, mapper) => events.distinct();

  /// asyncExpand(): 비동기적으로 이벤트 확장
  /// 각 이벤트를 처리하고 비동기적으로 여러 개의 하위 이벤트 생성 가능
  EventTransformer<Event> asyncExpand<Event>() =>
      (events, EventMapper<Event> mapper) => events.asyncExpand(mapper);

  /// both [distinct] and [asyncExpand]
  /// distinctAsyncExpand(): 중복 제거 후 비동기 이벤트 확장
  /// 중복 이벤트를 방지하면서 + 여러 하위 이벤트를 비동기적으로 처리
  EventTransformer<Event> distinctAsyncExpand<Event>() =>
      (events, mapper) => events.distinct().asyncExpand(mapper);
}

/*
< 사용 예시 > - transformer에 원하는 이벤트 처리 방식을 지정
class MyBloc extends BaseBlocDelegate<MyEvent, MyState> with EventTransformerMixin<MyEvent, MyState> {
  MyBloc() : super() {
    on<MyEvent>(
      (event, emit) async {
        // 이벤트 처리 로직
      },
      transformer: sequential(), // 이벤트를 순차적으로 처리
    );
  }
}
 */
