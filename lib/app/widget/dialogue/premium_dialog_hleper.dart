import 'package:flutter/material.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/app/enums/user_role.dart';
import 'package:kakikaki/app/widget/dialogue/common_dialogue.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/supabase_utils.dart';

class PremiumDialogHelper {
  PremiumDialogHelper._();

  static Future<void> showPremiumGuide(BuildContext context,
      {required String message}) async {
    final globalState = getIt<GlobalBloc>().state;
    final userId = globalState.user?.id;
    bool trialUsed = globalState.trialUsed;
    final client = SupabaseUtils.getClientOrNull();

    // 계정 전환 직후에도 stale state를 피하려고 DB 값을 우선 조회합니다.
    if (client != null && userId != null) {
      try {
        final res = await client
            .from('users')
            .select('trial_used')
            .eq('id', userId)
            .maybeSingle();
        if (res != null) {
          trialUsed = res['trial_used'] == true;
        }
      } catch (_) {}
    }

    if (!context.mounted) return;

    if (trialUsed) {
      // 2. 이미 체험을 쓴 유저: [결제하러 가기] 버튼이 있는 프리미엄 안내 팝업
      final goToPay = await CommonDialogue.showTwoChoiceConfirmDialogue(
        context: context,
        title: context.l10n.premium_guide_title,
        content: context.l10n.premium_guide_subscribe_content(message),
        elevatedButtonText: context.l10n.premium_guide_go_to_pay,
        outlineButtonText: context.l10n.action_cancel,
      );

      if (goToPay == true && context.mounted) {
        // TODO: 결제 기능 구현 후 결제 화면으로 이동하게 바꾸기
        await CommonDialogue.showOneChoiceDialogue(
          context: context,
          title: context.l10n.premium_payment_coming_soon_title,
          content: context.l10n.premium_payment_coming_soon_content,
          elevatedButtonText: context.l10n.action_confirm,
          onElevatedButtonPressed: () {},
        );
      }
    } else {
      // 3. 아직 체험을 안 쓴 유저: [무료로 시작하기] 팝업
      final startTrial = await CommonDialogue.showTwoChoiceConfirmDialogue(
        context: context,
        title: context.l10n.premium_trial_title,
        content: context.l10n.premium_trial_start_content(message),
        elevatedButtonText: context.l10n.premium_trial_start_button,
        outlineButtonText: context.l10n.premium_trial_later_button,
      );

      // (아래 RPC 호출 로직은 무료 시작을 "수락"했을 때만 도는 거라 완벽합니다)
      if (startTrial == true && context.mounted) {
        if (client != null && userId != null) {
          try {
            final response = await client
                .rpc('start_free_trial', params: {'p_user_id': userId});

            final success = response is Map<String, dynamic>
                ? response['success'] == true
                : false;
            final msg = response is Map<String, dynamic>
                ? (response['message']?.toString() ?? '')
                : '';

            if (success) {
              await client
                  .from('users')
                    .update({'role': UserRole.premium.name}).eq('id', userId);

              getIt<GlobalBloc>().add(const GlobalEvent.refreshUserInfo());

              if (context.mounted) {
                await CommonDialogue.showOneChoiceDialogue(
                  context: context,
                  title: context.l10n.premium_trial_started_title,
                  content: msg.isNotEmpty
                      ? msg
                      : context.l10n.premium_trial_started_default_content,
                  elevatedButtonText: context.l10n.action_confirm,
                  onElevatedButtonPressed: () {},
                );
              }
            } else {
              if (context.mounted) {
                final goToPay =
                    await CommonDialogue.showTwoChoiceConfirmDialogue(
                  context: context,
                  title: context.l10n.premium_trial_unavailable_title,
                  content: msg.isNotEmpty
                      ? msg
                      : context.l10n.premium_trial_unavailable_default_content,
                  elevatedButtonText: context.l10n.premium_guide_go_to_pay,
                  outlineButtonText: context.l10n.action_cancel,
                );

                if (goToPay == true && context.mounted) {
                  // TODO: 결제 기능 구현 후 결제 화면으로 이동하게 바꾸기
                  await CommonDialogue.showOneChoiceDialogue(
                    context: context,
                    title: context.l10n.premium_payment_coming_soon_title,
                    content: context.l10n.premium_payment_coming_soon_content,
                    elevatedButtonText: context.l10n.action_confirm,
                    onElevatedButtonPressed: () {},
                  );
                }
              }
            }
          } catch (_) {
            if (context.mounted) {
              await CommonDialogue.showOneChoiceDialogue(
                context: context,
                title: context.l10n.premium_trial_start_error_title,
                content: context.l10n.premium_trial_start_error_content,
                elevatedButtonText: context.l10n.action_confirm,
                onElevatedButtonPressed: () {},
              );
            }
          }
        }
      }
    }
  }
}
