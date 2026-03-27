import 'package:flutter/material.dart';
import 'package:kakikaki/app/widget/view/common_appbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';

class OpenSourceLicensePage extends StatelessWidget {
  const OpenSourceLicensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.white,
      appBar: DefaultCommonAppbar(
        title: context.l10n.open_source_license_title,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _buildSectionTitle(
                  context, context.l10n.open_source_kanji_source),
              const SizedBox(height: 12),
              _buildLicenseCard(
                context,
                title: 'KanjiVG',
                description: context.l10n.open_source_kanjivg_description,
                websiteUrl: 'http://kanjivg.tagaini.net',
              ),
              const SizedBox(height: 32),
              _buildSectionTitle(
                  context, context.l10n.open_source_license_info),
              const SizedBox(height: 12),
              _buildLicenseInfoCard(
                context,
                'Creative Commons Attribution-Share Alike 3.0',
                context.l10n.open_source_cc_description,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: context.h5_600Style.copyWith(color: Palette.gray90),
    );
  }

  Widget _buildLicenseCard(
    BuildContext context, {
    required String title,
    required String description,
    required String websiteUrl,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.gray10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.gray20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: context.h6_600Style.copyWith(color: Palette.gray90),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_new, size: 20),
                color: context.palette.primary,
                onPressed: () async {
                  final uri = Uri.parse(websiteUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                tooltip: context.l10n.tooltip_open_website,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: context.h7_400Style.copyWith(
              color: Palette.gray70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLicenseInfoCard(
    BuildContext context,
    String title,
    String content,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Palette.gray10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.gray20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.h6_600Style.copyWith(color: Palette.gray90),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: context.h7_400Style.copyWith(
              color: Palette.gray70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
