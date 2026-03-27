import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/view/empty_state_widget.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';

class InquiryListPage extends StatefulWidget {
  const InquiryListPage({super.key});

  @override
  State<InquiryListPage> createState() => _InquiryListPageState();
}

class _InquiryListPageState
    extends BaseScaffoldPageState<InquiryListPage, MyBloc, MyState> {
  _InquiryListPageState()
      : super(
            horizontalMargin: 0,
            verticalMargin: 0,
            isBottomNavigationBar: false);

  @override
  void initState() {
    super.initState();
    bloc.add(const MyInquiryListLoadRequested());
  }

  @override
  bool get enablePullToRefresh => true;

  @override
  Future<void> onRefresh() async =>
      bloc.add(const MyInquiryListLoadRequested());

  @override
  String? get appBarTitle => context.l10n.my_page_inquiry;

  @override
  Widget buildPage(BuildContext context, MyState state) {
    return Stack(
      children: [
        if (!commonState.isLoading &&
            !commonState.isError &&
            state.inquiries.isEmpty)
          EmptyStateWidget(
            icon: Icons.inbox_outlined,
            iconSize: 64,
            iconColor: Palette.gray50,
            text: context.l10n.inquiry_list_empty,
            textStyle: context.h6_400Style.copyWith(color: Palette.gray50),
            topPadding: 160,
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: state.inquiries.length,
            itemBuilder: (context, index) =>
                _buildInquiryItem(context, state.inquiries[index]),
          ),
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: CommonElevatedButton(
            text: context.l10n.inquiry_list_new_button,
            onPressed: () {
              context
                  .push('/my/inquiry/new')
                  .then((_) => bloc.add(const MyInquiryListLoadRequested()));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInquiryItem(BuildContext context, Map<String, dynamic> inquiry) {
    final category = inquiry['category'] as String? ?? 'etc';
    final title = inquiry['title'] as String? ?? '';
    final content = inquiry['content'] as String? ?? '';
    final status = inquiry['status'] as String? ?? 'pending';
    final createdAt = inquiry['created_at'] as String?;
    final adminReply = inquiry['admin_reply'] as String?;

    String categoryLabel;
    Color categoryColor;
    Color categoryBgColor;

    switch (category) {
      case 'bug':
        categoryLabel = context.l10n.inquiry_category_error;
        categoryColor = Palette.red50;
        categoryBgColor = Palette.red50.withExactOpacity(0.1);
        break;
      case 'feature_request':
        categoryLabel = context.l10n.inquiry_category_suggestion;
        categoryColor = Palette.blue50;
        categoryBgColor = Palette.blue50.withExactOpacity(0.1);
        break;
      case 'etc':
      default:
        categoryLabel = context.l10n.category_other;
        categoryColor = Palette.gray70;
        categoryBgColor = Palette.gray20;
        break;
    }

    final effectiveStatus =
        (adminReply != null && adminReply.isNotEmpty) ? 'resolved' : status;

    String statusLabel;
    Color statusColor;
    Color statusBgColor;

    switch (effectiveStatus) {
      case 'pending':
        statusLabel = context.l10n.inquiry_status_pending;
        statusColor = Palette.gray70;
        statusBgColor = Palette.gray20;
        break;
      case 'in_progress':
        statusLabel = context.l10n.inquiry_status_processing;
        statusColor = context.palette.primary;
        statusBgColor = context.palette.primary.withExactOpacity(0.1);
        break;
      case 'resolved':
        statusLabel = context.l10n.inquiry_status_answered;
        statusColor = context.palette.onPrimary;
        statusBgColor = context.palette.primary;
        break;
      default:
        statusLabel = context.l10n.inquiry_status_pending;
        statusColor = Palette.gray70;
        statusBgColor = Palette.gray20;
        break;
    }

    DateTime? date;
    if (createdAt != null) {
      try {
        date = DateTime.parse(createdAt);
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Palette.gray20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // [Guideline 1] 선언만 해두고 안 쓰던 색상 변수들을 드디어 적용했습니다!
              CommonChip(
                  label: categoryLabel,
                  labelColor: categoryColor,
                  backgroundColor: categoryBgColor),
              const SizedBox(width: 8),
              CommonChip(
                  label: statusLabel,
                  labelColor: statusColor,
                  backgroundColor: statusBgColor),
              const Spacer(),
              if (date != null)
                Text(
                    '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}',
                    style: context.h7_400Style.copyWith(color: Palette.gray50)),
            ],
          ),
          if (title.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(title, style: context.h6_700Style),
          ],
          const SizedBox(height: 8),
          Text(content,
              style: context.h6_400Style,
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          if (adminReply != null && adminReply.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                CommonDialogue.showOneChoiceDialogue(
                  context: context,
                  title: context.l10n.inquiry_admin_reply,
                  content: adminReply,
                  elevatedButtonText: context.l10n.action_confirm,
                  onElevatedButtonPressed: () {},
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Palette.gray10,
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.inquiry_admin_reply,
                        style: context.h7_600Style
                            .copyWith(color: Palette.gray50)),
                    const SizedBox(height: 8),
                    Text(adminReply,
                        style: context.h6_400Style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
