part of 'sign_in_bloc.dart';

@freezed
class SignInPageState with _$SignInPageState {
  const factory SignInPageState({
    // 어느 버튼이 눌렸는지 BLoC 상태로 관리하여 해당 버튼만 스피너를 돌림
    SocialType? loadingSocialType,
  }) = _SignInPageState;
}
