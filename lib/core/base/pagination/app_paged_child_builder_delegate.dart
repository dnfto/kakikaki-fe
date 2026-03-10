import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:kakikaki/app/widget/widget.dart';

/// 페이지네이션 UI 빌더 델리게이트
///
/// 로딩, 에러, 빈 상태 등을 자동으로 처리
class AppPagedChildBuilderDelegate<T> extends PagedChildBuilderDelegate<T> {
  AppPagedChildBuilderDelegate({
    required super.itemBuilder,
    super.firstPageErrorIndicatorBuilder = _pageErrorIndicator,
    super.newPageErrorIndicatorBuilder = _pageErrorIndicator,
    super.firstPageProgressIndicatorBuilder = _pageProgressIndicator,
    super.newPageProgressIndicatorBuilder = _pageProgressIndicator,
    super.animateTransitions = true,
    super.noItemsFoundIndicatorBuilder = _noItemPage,
    super.noMoreItemsIndicatorBuilder,
  });
}

Widget _pageErrorIndicator(BuildContext context) {
  final AppLocalizations l10n = context.l10n;

  return Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.refresh, color: context.palette.onSurface),
      Text(l10n.error_something_went_wrong, style: context.textStyle.bodySmall),
      const SizedBox(height: 8),
    ]),
  );
}

Widget _pageProgressIndicator(BuildContext context) {
  return const DefaultCircularProgressIndicator();
}

Widget _noItemPage(BuildContext context) {
  final AppLocalizations l10n = context.l10n;
  return Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.add, color: context.palette.primary),
      Text(l10n.error_page_no_item,
          style: context.h6_400Style.copyWith(
            color: context.palette.shadow,
          )),
      const SizedBox(height: 8),
    ]),
  );
}
