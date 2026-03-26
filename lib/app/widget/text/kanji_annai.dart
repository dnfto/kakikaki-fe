import 'package:flutter/widgets.dart';
import 'package:kakikaki/core/extension/extension.dart';

class KanjiAnnai extends StatelessWidget {
  const KanjiAnnai({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.palette.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        context.l10n.study_kanji_annai,
        style: context.h8_600Style.copyWith(color: context.palette.onPrimary),
      ),
    );
  }
}
