import 'package:kakikaki/app/widget/view/common_appbar.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final globalState = context.watch<GlobalBloc>().state;
    final currentLanguage = globalState.languageCode;

    return Scaffold(
      appBar: DefaultCommonAppbar(
        title: l10n.settings_language_title,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: BubbleContainer(
                text: l10n.settings_language_feedback_fixed_notice,
                arrowDirection: ArrowDirection.bottomCenter,
              ),
            ),
            _buildLanguageOption(
              context,
              title: '🇰🇷 ${l10n.settings_language_korean}',
              languageCode: 'ko',
              isSelected: currentLanguage == 'ko',
              onTap: () => _changeLanguage(context, 'ko'),
            ),
            _buildLanguageOption(
              context,
              title: '🇯🇵 ${l10n.settings_language_japanese}',
              languageCode: 'ja',
              isSelected: currentLanguage == 'ja',
              onTap: () => _changeLanguage(context, 'ja'),
            ),
            _buildLanguageOption(
              context,
              title: '🇺🇸 ${l10n.settings_language_english}',
              languageCode: 'en',
              isSelected: currentLanguage == 'en',
              onTap: () => _changeLanguage(context, 'en'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String title,
    required String languageCode,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: context.h6_400Style,
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: context.palette.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _changeLanguage(BuildContext context, String languageCode) {
    final globalBloc = context.read<GlobalBloc>();
    // AppChangeLocale은 global_bloc.dart의 part이므로 직접 사용 가능
    globalBloc.add(
      GlobalEvent.changeLocale(Locale(languageCode)),
    );
  }
}
