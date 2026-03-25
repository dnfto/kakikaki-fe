part of 'sign_in_bloc.dart';

@freezed
class SignInPageEvent with _$SignInPageEvent {
  const factory SignInPageEvent.appleSignInRequested() = SignInAppleRequested;
  const factory SignInPageEvent.googleSignInRequested() = SignInGoogleRequested;
  const factory SignInPageEvent.kakaoSignInRequested() = SignInKakaoRequested;
}
