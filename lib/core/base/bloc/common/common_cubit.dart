import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'common_state.dart';
part 'common_cubit.freezed.dart';

/// Cubit status of page
///
/// * Show loading page
/// * Get [Exception] when page Error

// Cubit 클래스는 하나의 상태만 관리한다.
class CommonCubit extends Cubit<CommonState> {
  // 생성자에서 부모 클래스 Cubit의 생성자 호출
  // super()를 사용해 초기 상태 전달
  CommonCubit() : super(const CommonState.initial());

  /// 상태를 loading으로 변경
  /// emit() 메서드: 상태를 변경할 때 사용
  /// 화면 전체에 로딩을 띄우는 걸로, 버튼 같이 국소 부위에 로딩 상태를 줄 때는 각 모듈에서 로딩 상태를 줄 수 있도록 구현
  void loadingEmitted() => emit(const CommonState.loading());

  /// Change status page to error with [Exception]
  void exceptionEmitted([Exception? exception]) =>
      emit(CommonState.error(exception));

  /// 상태를 success로 변경
  void successEmitted() => emit(const CommonState.success());

  /// 페이지가 시작되었을 때 상태를 initial 상태로 되돌린다.
  void initialEmitted() => emit(const CommonState.initial());
}
