import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:kakikaki/core/config/config.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/app/service/auth_service.dart';
import 'package:kakikaki/core/base/bloc/base_bloc.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/utils/log_utils.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

part 'sign_in_bloc.freezed.dart';
part 'sign_in_event.dart';
part 'sign_in_state.dart';

@injectable
class SignInPageBloc extends BaseBloc<SignInPageEvent, SignInPageState> {
  SignInPageBloc() : super(const SignInPageState()) {
    on<SignInAppleRequested>(_onAppleSignInRequested);
    on<SignInKakaoRequested>(_onKakaoSignInRequested);
    on<SignInGoogleRequested>(_onGoogleSignInRequested);
  }

  bool _isUserCancelledError(Object error) {
    if (error is PlatformException) {
      final code = error.code.toLowerCase();
      return code == 'canceled' ||
          code == 'cancelled' ||
          code == 'sign_in_canceled' ||
          code == '12501';
    }
    final message = error.toString().toLowerCase();
    return message.contains('canceled') ||
        message.contains('cancelled') ||
        message.contains('sign_in_canceled') ||
        message.contains('cancel');
  }

  bool _isAppleUserCancelledError(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      // iOS에서 닫기/취소 시 canceled 또는 unknown(1000)으로 들어오는 케이스가 있음
      return error.code == AuthorizationErrorCode.canceled ||
          error.code == AuthorizationErrorCode.unknown;
    }
    final message = error.toString().toLowerCase();
    return message.contains('authenticationservices.authorizationerror error 1000') ||
        message.contains('authorizationerror error 1000');
  }

  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor; // iOS 고유 ID
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Android 고유 ID
      }
    } catch (e) {
      Log.e('기기 ID 가져오기 실패: $e');
    }
    return null;
  }

// ==========================================
  // 🍎 Apple 로그인 로직
  // ==========================================
  Future<void> _onAppleSignInRequested(
      SignInAppleRequested event, Emitter<SignInPageState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      doOnEventStart: () =>
          emit(state.copyWith(loadingSocialType: SocialType.apple)),
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        if (client == null) throw Exception('서버 초기화가 완료되지 않았어요.');

        // 1. Nonce 생성 (애플 보안 검증용)
        final rawNonce = client.auth.generateRawNonce();
        final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

        // 2. 기기에서 애플 로그인 창 띄우기
        late final AuthorizationCredentialAppleID appleCredential;
        try {
          appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: hashedNonce, // 해시된 Nonce 전달
          );
        } catch (e) {
          if (_isAppleUserCancelledError(e) || _isUserCancelledError(e)) {
            Log.i('사용자가 Apple 로그인을 취소함');
            return;
          }
          rethrow;
        }

        final idToken = appleCredential.identityToken;
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Apple 로그인 토큰을 받지 못했어요.');
        }

        // 3. Supabase에 인증 요청
        final authResponse = await client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: rawNonce, // 원본 Nonce 전달 (Supabase가 알아서 검증)
        );

        if (authResponse.session == null) {
          throw Exception('Apple 로그인 중 오류가 발생했어요.');
        }

        // 애플은 최초 로그인 시에만 이름을 줍니다.
        final appleName = (appleCredential.givenName != null ||
                appleCredential.familyName != null)
            ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim()
            : null;

        await AuthService.processAuthSession(
          authResponse.session!,
          getIt<GlobalBloc>(),
          customNickname: appleName,
        );

        final deviceId = await _getDeviceId();
        if (deviceId != null) {
          await client.from('users').update({'device_id': deviceId}).eq(
              'id', authResponse.session!.user.id);
        }
      },
      doOnEventCompleted: () => emit(state.copyWith(loadingSocialType: null)),
    );
  }

  // ==========================================
  // 🇬 Google 로그인 로직
  // ==========================================
  Future<void> _onGoogleSignInRequested(
      SignInGoogleRequested event, Emitter<SignInPageState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      doOnEventStart: () =>
          emit(state.copyWith(loadingSocialType: SocialType.google)),
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        if (client == null) throw Exception('서버 초기화가 완료되지 않았어요.');

        // Config에서 환경변수 값을 가져옵니다. (하드코딩 제거!)
        final webClientId = Config.googleWebClientId;
        final iosClientId = Config.googleIosClientId;

        if (webClientId.isEmpty || iosClientId.isEmpty) {
          throw Exception('구글 클라이언트 ID가 설정되지 않았습니다.');
        }

        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: Platform.isIOS ? iosClientId : null,
          // Supabase 검증을 위해 serverClientId는 반드시 '웹 클라이언트 ID'여야 합니다.
          serverClientId: webClientId,
        );

        GoogleSignInAccount? googleUser;
        try {
          googleUser = await googleSignIn.signIn();
        } catch (e) {
          if (_isUserCancelledError(e)) {
            Log.i('사용자가 구글 로그인을 취소함');
            return;
          }
          rethrow;
        }
        if (googleUser == null) {
          Log.i('사용자가 구글 로그인을 취소함');
          return;
        }

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        final accessToken = googleAuth.accessToken;

        if (idToken == null) {
          throw Exception('구글 로그인 토큰을 받지 못했어요.');
        }

        final authResponse = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (authResponse.session == null) {
          throw Exception('구글 로그인 중 오류가 발생했어요.');
        }

        final googleName = googleUser.displayName;

        await AuthService.processAuthSession(
          authResponse.session!,
          getIt<GlobalBloc>(),
          customNickname: googleName,
        );

        final deviceId = await _getDeviceId();
        if (deviceId != null) {
          await client.from('users').update({'device_id': deviceId}).eq(
              'id', authResponse.session!.user.id);
        }
      },
      doOnEventCompleted: () => emit(state.copyWith(loadingSocialType: null)),
    );
  }

  Future<void> _onKakaoSignInRequested(
      SignInKakaoRequested event, Emitter<SignInPageState> emit) async {
    await runBlocCatching(
      handleLoading: false,
      handleToast: true,
      doOnEventStart: () =>
          emit(state.copyWith(loadingSocialType: SocialType.kakao)),
      action: () async {
        final client = SupabaseUtils.getClientOrNull();
        if (client == null) throw Exception('서버 초기화가 완료되지 않았어요.');

        kakao.OAuthToken token;
        if (await kakao.isKakaoTalkInstalled()) {
          try {
            token = await kakao.UserApi.instance.loginWithKakaoTalk();
          } catch (error) {
            if (_isUserCancelledError(error)) {
              Log.i('사용자가 카카오톡 로그인을 취소함');
              return;
            }
            try {
              token = await kakao.UserApi.instance.loginWithKakaoAccount();
            } catch (e) {
              if (_isUserCancelledError(e)) {
                Log.i('사용자가 카카오 계정 로그인을 취소함');
                return;
              }
              rethrow;
            }
          }
        } else {
          try {
            token = await kakao.UserApi.instance.loginWithKakaoAccount();
          } catch (e) {
            if (_isUserCancelledError(e)) {
              Log.i('사용자가 카카오 계정 로그인을 취소함');
              return;
            }
            rethrow;
          }
        }

        if (token.idToken == null) {
          throw Exception('OIDC 토큰이 없습니다. 카카오 설정을 확인해 주세요.');
        }

        final authResponse = await client.auth.signInWithIdToken(
          provider: OAuthProvider.kakao,
          idToken: token.idToken!,
        );
        if (authResponse.session == null) {
          throw Exception('카카오 로그인 중 오류가 발생했어요.');
        }

        final kakaoUser = await kakao.UserApi.instance.me();
        final kakaoName = kakaoUser.kakaoAccount?.profile?.nickname;

        await AuthService.processAuthSession(
          authResponse.session!,
          getIt<GlobalBloc>(),
          customNickname: kakaoName,
        );

        // 카카오 로그인 성공 직후에도 기기 ID 저장!
        final deviceId = await _getDeviceId();
        if (deviceId != null) {
          await client.from('users').update({'device_id': deviceId}).eq(
              'id', authResponse.session!.user.id);
        }
      },
      doOnEventCompleted: () => emit(state.copyWith(loadingSocialType: null)),
    );
  }
}
