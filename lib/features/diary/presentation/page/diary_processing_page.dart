import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/diary/domain/model/diary_flow_models.dart';
import 'package:kakikaki/features/diary/presentation/bloc/processing/diary_processing_bloc.dart';

class DiaryProcessingPage extends StatefulWidget {
  const DiaryProcessingPage({super.key, required this.payload});
  final DiaryWritePayload payload;

  @override
  State<DiaryProcessingPage> createState() => _DiaryProcessingState();
}

class _DiaryProcessingState extends BaseScaffoldPageState<DiaryProcessingPage,
    DiaryProcessingBloc, DiaryProcessingState> {
  _DiaryProcessingState()
      : super(
          isAppBar: false,
          backgroundColor: Palette.gray10,
          horizontalMargin: 0,
          verticalMargin: 0,
          automaticallyImplyLeading: false,
          isBottomNavigationBar: false,
        );

  @override
  void initState() {
    super.initState();
    bloc.add(DiaryProcessingEvent.started(widget.payload));
  }

  @override
  Widget buildPage(BuildContext context, DiaryProcessingState state) {
    return PopScope(
      canPop: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            Text(
              state.isDone
                  ? context.l10n.diary_processing_done_title
                  : context.l10n.diary_processing_analyzing_title,
              style: context.h2_700Style,
            ),
            const SizedBox(height: 10),
            Text(
              state.isDone
                  ? context.l10n.diary_processing_done_subtitle
                  : context.l10n.diary_processing_analyzing_subtitle,
              style: context.h4_400Style.copyWith(color: Palette.gray50),
            ),
            const SizedBox(height: 44),
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: Palette.gray10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Lottie.asset(
                LottiePath.loader,
                fit: BoxFit.contain,
                repeat: !state.isDone,
              ),
            ),
            const Spacer(),
            if (state.isError) ...[
              const SizedBox(height: 8),
              Text(
                state.errorMessage,
                style: context.h7_400Style.copyWith(color: Palette.red50),
                textAlign: TextAlign.center,
              ),
            ],
            if (!state.isDone && !state.isError)
              Column(
                children: [
                  BubbleContainer(
                      arrowDirection: ArrowDirection.bottomCenter,
                      text: context.l10n.diary_processing_other_screen),
                  const SizedBox(height: 12),
                  CommonElevatedButton(
                      text: context.l10n.diary_processing_go_home,
                      onPressed: () => context.go('/home')),
                ],
              ),
            if (state.isDone && !state.isError)
              CommonElevatedButton(
                text: context.l10n.diary_processing_go_feedback,
                backgroundColor: Palette.black,
                enabledTextColor: Palette.white,
                onPressed: state.result == null
                    ? null
                    : () async {
                        final result = await context.push<bool>(
                            '/diary/feedback?fromHome=true',
                            extra: state.result);
                        if (mounted && result == true) context.go('/home');
                      },
              ),
            if (state.isError)
              CommonElevatedButton(
                text: context.l10n.diary_processing_go_home,
                backgroundColor: Palette.black,
                enabledTextColor: Palette.white,
                onPressed: () => context.go('/home'),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
