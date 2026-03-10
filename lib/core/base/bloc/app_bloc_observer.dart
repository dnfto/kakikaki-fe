import 'package:kakikaki/core/config/config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kakikaki/core/utils/log_utils.dart';

/// BlocObserver를 확장하여 BloC의 생명주기, 이벤트, 상태 변경, 에러를 감지하고 로깅한다.
///
/// * BLoC 생명주기 관리: 생성(onCreate), 닫힘(onClose), 상태 변경(onChange), 에러 발생(onError) 등을 감지
/// * 이벤트 및 트랜지션 로깅: 이벤트가 추가될 때 호출되는 onEvent와 상태 변경 전/후의 트랜지션을 로깅하는 onTransition
/// * 설정 기반 로깅: Config 클래스에서 정의된 플래그를 통해 각 로깅 기능을 활성화/비활성화할 수 있다.
class GlobalBlocObserver extends BlocObserver {
  GlobalBlocObserver({
    // 각 로깅 기능을 제어할 수 있는 Boolean 플래그 설정
    // 기본값으로 Config에서 설정한 값을 사용한다.
    this.logOnChange = Config.logOnBlocChange,
    this.logOnCreate = Config.logOnBlocCreate,
    this.logOnClose = Config.logOnBlocClose,
    this.logOnError = Config.logOnBlocError,
    this.logOnEvent = Config.logOnBlocEvent,
    this.logOnTransition = Config.logOnBlocTransition,
  });

  final bool logOnChange;
  final bool logOnCreate;
  final bool logOnClose;
  final bool logOnError;
  final bool logOnEvent;
  final bool logOnTransition;

  /// onChange: 상태 변경 감지. bloc의 상태가 변경될 때 호출된다.
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (logOnChange) {
      // Log.d를 사용해 상태의 이전 값과 새로운 값을 출력
      // change: 상태 변화의 세부 정보를 포함
      Log.d('onChange $change', name: bloc.runtimeType.toString());
    }
  }

  /// onCreate: 생성 감지. BLoC 또는 Cubit이 생성될 때 호출된다.
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (logOnCreate) {
      // 생성된 BLoC 타입과 로그 메시지를 출력
      Log.d('created', name: bloc.runtimeType.toString());
    }
  }

  /// onClose: 닫힘 감지. bloc 또는 Cubit이 닫힐 때 호출된다.
  /// 메모리 정리를 위해 BLoC가 제거되는 시점을 로깅한다.
  @override
  void onClose(BlocBase<dynamic> bloc) {
    super.onClose(bloc);
    if (logOnClose) {
      Log.d('closed', name: bloc.runtimeType.toString());
    }
  }

  /// onError: 에러 감지. Bloc 내에서 에러 발생 시 호출된다.
  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    if (logOnError) {
      // 에러 내용과 발생한 BLoC 타입을 로그로 출력
      Log.d('onError $error', name: bloc.runtimeType.toString());
    }
  }

  // onEvent: 이벤트 감지. Bloc에 이벤트가 추가될 때 호출된다.
  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (logOnEvent) {
      // 이벤트 내용을 로그에 출력
      Log.d('onEvent $event', name: bloc.runtimeType.toString());
    }
  }

  /// onTransition: 상태 전환 감지.
  /// 트랜지션은 이벤트에 의해 상태가 변경되기 전/후를 나타내는 객체임.
  /// transition에는 이전 상태, 이벤트, 새로운 상태가 포함된다.
  @override
  void onTransition(
      Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> transition) {
    super.onTransition(bloc, transition);
    if (logOnTransition) {
      Log.d('onTransition $transition', name: bloc.runtimeType.toString());
    }
  }
}
/*
< 사용 예시 >: GlobalBlocObserver를 BLoC 라이브러리에 등록
void main() {
  Bloc.observer = GlobalBlocObserver(); // BLoC 옵저버 등록
  runApp(MyApp());
}

 */
