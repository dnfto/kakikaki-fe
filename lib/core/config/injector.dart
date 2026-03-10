import 'package:kakikaki/core/config/injector.config.dart'; // Injectable 패키지가 자동 생성
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

/// 의존성 주입을 위해 GetIt과 Injectable 사용
/*
get_it: Service Locator 패턴을 구현하는 패키지로, 객체를 중앙화된 위치에서 관리
injectable: 의존성 주입을 더 쉽게 설정하도록 돕는 패키지로, 주석 기반으로 DI를 설정하고, build_runner를 사용해 코드를 자동으로 생성
 */
final GetIt getIt = GetIt.instance;
// GetIt.instance를 사용해 싱글톤 인스턴스를 생성
// 모든 객체(의존성)는 이 getIt 인스턴스를 통해 관리된다.

/// initializes the registration of main-scope dependencies inside of GetIt
@injectableInit
Future<void> configureInjection() async => getIt.init();

// @injectableInit: Injectable에서 제공하는 어노테이션으로, 자동 생성된 DI 설정 파일(injector.config.dart)을 초기화
// getIt.init(): injector.config.dart 파일에 정의된 객체들을 GetIt에 등록한다.
// getIt.init() 메서드를 호출하면 의존성들이 자동으로 주입된다.


/*
< DI 사용 흐름 >
1. 객체 정의: 각 객체에 @injectable, @singleton 등의 어노테이션을 추가한다.
@singleton
class ApiService {
  void fetchData() => Log.i("데이터를 가져온다.");
}

2. 코드 생성: `flutter pub run build_runner build`를 실행해 DI 설정 파일을 자동으로 생성한다.

3. 초기화: `configureInjection()`을 호출해 GetIt에 의존성을 등록한다.

4. 객체 사용: getIt를 통해 등록된 객체를 가져와 사용한다.
final apiService = getIt<ApiService>();
apiService.fetchData();
 */