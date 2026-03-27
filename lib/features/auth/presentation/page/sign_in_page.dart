import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kakikaki/app/enums/auth_enums.dart';
import 'package:kakikaki/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/auth/presentation/widget/social_sign_in_button.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState
    extends BaseScaffoldPageState<SignInPage, SignInPageBloc, SignInPageState> {
  _SignInPageState()
      : super(
          backgroundColor: const Color(0xFF1A1B1D),
          isAppBar: false,
          isBottomNavigationBar: false,
        );

  /// 로고와 달 이미지를 포함한 상단 섹션
  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60), // 최상단 여백
        Text(
          context.l10n.auth_tagline,
          style: context.h5_500Style.copyWith(color: Palette.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'カキカキ',
          style: context.h2_700Style.copyWith(
            color: const Color(0xFFFEE500).mixWithWhite(0.45),
            fontSize: 40,
          ),
        ),
        const SizedBox(height: 40),
        _buildMoonImage(),
      ],
    );
  }

  /// 배경과 블렌딩된 달 이미지 (이중 ShaderMask)
  Widget _buildMoonImage() {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent
        ],
        stops: [0.0, 0.22, 0.78, 1.0],
      ).createShader(bounds),
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (bounds) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent
          ],
          stops: [0.0, 0.28, 0.72, 1.0],
        ).createShader(bounds),
        child: Image.asset(
          ImagePath.moon,
          width: 300,
          height: 300,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget buildPage(BuildContext context, SignInPageState state) {
    final loadingType = state.loadingSocialType;
    final isAnyLoading = loadingType != null;

    return Column(
      children: [
        const Spacer(),
        _buildHeaderSection(context),

        // 기기별 맞춤 여백
        SizedBox(
            height: context.isTablet
                ? context.screenHeight * 0.10
                : context.screenHeight * 0.05),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (Platform.isIOS) ...[
                SocialSignInButton(
                  text: context.l10n.auth_sign_in_apple,
                  iconPath: IconPath.signInWithApple,
                  backgroundColor: Palette.white,
                  textColor: Palette.black,
                  isLoading: loadingType == SocialType.apple,
                  isAnyLoading: isAnyLoading,
                  onPressed: () =>
                      bloc.add(const SignInPageEvent.appleSignInRequested()),
                ),
                const SizedBox(height: 16),
              ],
              SocialSignInButton(
                text: context.l10n.auth_sign_in_kakao,
                iconPath: IconPath.signInWithKakao,
                iconWidth: 34,
                backgroundColor: const Color(0xFFFEE500),
                textColor: Colors.black,
                isLoading: loadingType == SocialType.kakao,
                isAnyLoading: isAnyLoading,
                onPressed: () =>
                    bloc.add(const SignInPageEvent.kakaoSignInRequested()),
              ),
              const SizedBox(height: 16),
              SocialSignInButton(
                text: context.l10n.auth_sign_in_google,
                iconPath: IconPath.signInWithGoogle,
                iconWidth: 20,
                backgroundColor: Palette.white,
                textColor: Colors.black,
                isLoading: loadingType == SocialType.google,
                isAnyLoading: isAnyLoading,
                onPressed: () =>
                    bloc.add(const SignInPageEvent.googleSignInRequested()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }
}
