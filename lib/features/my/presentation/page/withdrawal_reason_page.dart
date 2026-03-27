import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/formatter_utils.dart';
import 'package:kakikaki/features/my/domain/enums/withdrawal_reasons.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';

/// 탈퇴 사유 선택 후 회원 탈퇴를 진행하는 페이지
class WithdrawalReasonPage extends StatefulWidget {
  const WithdrawalReasonPage({super.key});

  @override
  State<WithdrawalReasonPage> createState() => _WithdrawalReasonPageState();
}

class _WithdrawalReasonPageState
    extends BaseScaffoldPageState<WithdrawalReasonPage, MyBloc, MyState> {
  _WithdrawalReasonPageState()
      : super(
          horizontalMargin: 0,
          verticalMargin: 0,
          isBottomNavigationBar: false,
          backgroundColor: Palette.gray10,
        );

  final TextEditingController _customReasonController = TextEditingController();

  @override
  String get appBarTitle => context.l10n.withdrawal_title;

  @override
  void initState() {
    super.initState();
    // 텍스트가 입력될 때마다 '탈퇴하기' 버튼의 활성화 상태를 갱신하기 위해 화면을 다시 그림
    _customReasonController.addListener(() {
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _customReasonController.dispose();
    super.dispose();
  }

  @override
  void handleBlocStateListener(BuildContext context, MyState state) {
    super.handleBlocStateListener(context, state);

    // 탈퇴 성공 상태를 감지하면 로그인 화면으로 이동
    if (state.isWithdrawalSuccess) {
      context.go('/sign-in');
      bloc.add(const MyEvent.clearWithdrawalResult()); // 상태 초기화
    }
    // errorMessage 관련 로직은 BaseBloc이 토스트를 띄워주므로 삭제되었습니다.
  }

  @override
  Widget buildPage(BuildContext context, MyState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BubbleContainer(
            arrowDirection: ArrowDirection.bottomCenter,
            text: context.l10n.withdrawal_message,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: context.palette.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              // 하드코딩된 Map 대신 Enum.values를 사용합니다.
              children: WithdrawalReason.values.map((reason) {
                final isSelected = state.selectedReason == reason;
                return InkWell(
                  onTap: commonState.isLoading
                      ? null
                      : () => bloc.add(MyEvent.selectReason(reason)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          size: 24,
                          color: isSelected
                              ? context.palette.primary
                              : Palette.gray40,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            reason.label(context),
                            style: context.h6_400Style,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // String 비교('other') 대신 Enum(WithdrawalReason.other)과 비교합니다.
          if (state.selectedReason == WithdrawalReason.other) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: CommonTextFormField(
                controller: _customReasonController, // 컨트롤러 연결
                inputFormatters: const [
                  NoLeadingWhitespaceFormatter(),
                ],
                maxLines: 3,
                maxLength: 200,
                hintText: context.l10n.withdrawal_reason_hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Palette.gray20),
                ),
              ),
            ),
          ],
          const SizedBox(height: 32),
          Text(
            context.l10n.withdrawal_warning,
            style: context.h7_600Style.copyWith(color: context.palette.error),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final isOther = state.selectedReason == WithdrawalReason.other;
              // BLoC State가 아닌 컨트롤러에서 직접 텍스트 유무를 확인합니다.
              final hasCustomReason =
                  _customReasonController.text.trim().isNotEmpty;

              final canSubmit = state.selectedReason != null &&
                  !commonState.isLoading &&
                  !commonState.isError &&
                  (!isOther || hasCustomReason);

              return CommonElevatedButton(
                text: context.l10n.withdrawal_confirm,
                backgroundColor: canSubmit ? Palette.black : Palette.gray20,
                enabledTextColor: Palette.white,
                isEnabled: canSubmit,
                onPressed: canSubmit ? () => _onWithdrawPressed(isOther) : null,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onWithdrawPressed(bool isOther) async {
    final confirmed = await CommonDialogue.showTwoChoiceConfirmDialogue(
      context: context,
      title: context.l10n.withdrawal_confirm_dialog_title,
      content: context.l10n.withdrawal_confirm_dialog_content,
      outlineButtonText: context.l10n.action_cancel,
      elevatedButtonText: context.l10n.withdrawal_confirm,
      barrierDismissible: false,
    );
    if (confirmed != true || !mounted) return;

    // 여기서 UI의 context를 사용해 최종 텍스트를 결정합니다!
    String finalReason = '';
    if (isOther) {
      finalReason = _customReasonController.text.trim();
    } else {
      // state.selectedReason은 null이 아님이 버튼 활성화 로직에서 보장됨
      finalReason = bloc.state.selectedReason!.label(context);
    }

    // BLoC에는 완성된 문자열만 깔끔하게 전달
    bloc.add(MyEvent.withdrawalRequested(
      reasonLabel: finalReason,
    ));
  }
}
