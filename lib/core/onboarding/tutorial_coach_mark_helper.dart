import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// 코치마크가 한 세션에 여러 번 뜨거나 프레임 충돌이 나는 것을 방지하는 통합 매니저
class CoachMarkDisplayManager {
  bool _isShown = false;
  bool _isPending = false;

  /// 조건이 맞을 때 단 1회만 안전하게 코치마크를 띄웁니다.
  void showIfNeeded({
    required bool isReady,
    required bool isDone,
    required VoidCallback showAction,
    bool Function()? canShowNow,
  }) {
    // 이미 DB/로컬에서 완료된 상태면 shown 플래그를 초기화(계정 전환 대비)하고 종료
    if (isDone) {
      _isShown = false;
      return;
    }

    // 준비가 안 되었거나, 이미 띄우는 중이거나, 띄웠다면 무시
    if (!isReady || _isPending || _isShown) return;

    _isPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isPending = false;
      if (canShowNow != null && !canShowNow()) return;
      if (_isShown || isDone) return;
      _isShown = true;
      showAction();
    });
  }
}

/// [tutorial_coach_mark] 공통 스타일(설명 문구 + 스킵).
class TutorialCoachMarkHelper {
  TutorialCoachMarkHelper._();

  static TutorialCoachMark _buildSingleTarget({
    required GlobalKey keyTarget,
    required String description,
    required VoidCallback onComplete,
    String? skipLabel,
  }) {
    var completed = false;
    void guardComplete() {
      if (completed) return;
      completed = true;
      print('[TutorialCoachMarkHelper] guardComplete called');
      onComplete();
    }

    return TutorialCoachMark(
      targets: [
        TargetFocus(
          identify: keyTarget,
          keyTarget: keyTarget,
          shape: ShapeLightFocus.RRect,
          radius: 12,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              padding: const EdgeInsets.all(20),
              child: Text(
                description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ],
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      textSkip: skipLabel ?? 'SKIP',
      textStyleSkip: const TextStyle(
        color: Colors.white70,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      paddingFocus: 8,
      pulseEnable: false,
      onFinish: guardComplete,
      onSkip: () {
        print('[TutorialCoachMarkHelper] onSkip called');
        guardComplete();
        return true;
      },
    );
  }

  static void showSingleTarget({
    required BuildContext context,
    required GlobalKey keyTarget,
    required String description,
    required VoidCallback onComplete,
    String? skipLabel,
  }) {
    print('[TutorialCoachMarkHelper] showSingleTarget rootOverlay=true');
    _buildSingleTarget(
      keyTarget: keyTarget,
      description: description,
      onComplete: onComplete,
      skipLabel: skipLabel,
    ).show(context: context, rootOverlay: true);
  }
}
