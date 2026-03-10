part of 'common_cubit.dart';

@freezed
class CommonState with _$CommonState {
  const factory CommonState.loading() = _Loading;
  const factory CommonState.success() = _Success;
  const factory CommonState.error([Exception? exception]) = _Error;
  const factory CommonState.initial() = _Initial;

  const CommonState._();

  /// 페이지가 로딩 중인지 체크
  // maybewhen, orElse: Freezed 패키지를 사용할 때 상태를 처리하는 메서드
  // maybewhen: 선택적으로 특정 상태만 처리
  // orElse: maybewhen으로 처리하지 않은 나머지 상태에 대해 기본 동작을 정의
  bool get isLoading => maybeWhen(loading: () => true, orElse: () => false);
  // 즉 위 코드는 CommonState가 loading 상태일 때 true를 반환하고,
  // 그 외 다른 상태(e.g. success, error, inital)일 때는 false를 반환

  /// 페이지에서 데이터 요청 등의 작업이 성공한 상태인지 체크
  bool get isSuccess => maybeWhen(success: () => true, orElse: () => false);

  /// 페이지가 에러 상태인지 체크
  bool get isError => maybeWhen(error: (_) => true, orElse: () => false);

  /// 페이지가 시작됐는지 체크
  bool get isInitial => maybeWhen(initial: () => true, orElse: () => false);

  /// 페이지의 에러[Exception] 가져오기
  // whenOrNull: 특정 상태 처리 후 나머지는 null을 반환하는 Freezed 패키지의 메서드
  Exception? get exception => whenOrNull(error: (exception) => exception);
  // 즉 위 코드는 CommonState가 error 상태일 때만 Exception 객체를 반환하고, 그 외 상태에서는 null을 반환
}
