import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/base/base_page_state.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/config/injector.dart';
import 'package:kakikaki/app/bloc/global_bloc.dart';
import 'package:kakikaki/features/my/domain/enums/inquiry_category.dart';
import 'package:kakikaki/features/my/presentation/bloc/my_bloc.dart';

class InquiryPage extends StatefulWidget {
  const InquiryPage({super.key});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState
    extends BaseScaffoldPageState<InquiryPage, MyBloc, MyState> {
  _InquiryPageState()
      : super(
            horizontalMargin: 0,
            verticalMargin: 0,
            isBottomNavigationBar: false);

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  String? get appBarTitle => context.l10n.my_page_inquiry;

  @override
  void handleBlocStateListener(BuildContext context, MyState state) {
    super.handleBlocStateListener(context, state);
    if (state.isInquirySuccess) {
      // BLoC이 토스트를 띄워주므로 화면만 닫고 상태를 리셋합니다.
      Navigator.pop(context);
      bloc.add(const MyEvent.clearInquiryResult());
    }
  }

  @override
  Widget buildPage(BuildContext context, MyState state) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(context.l10n.inquiry_category, style: context.h6_700Style),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                  color: Palette.gray10,
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<InquiryCategory>(
                initialValue: state.selectedCategory,
                decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none),
                items: InquiryCategory.values.map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(_categoryLabel(category)));
                }).toList(),
                onChanged: (InquiryCategory? value) {
                  if (value != null) {
                    bloc.add(MyEvent.inquiryCategoryChanged(value));
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(context.l10n.inquiry_title_optional,
                style: context.h6_700Style),
            const SizedBox(height: 8),
            CommonTextFormField(
                controller: _titleController,
                hintText: context.l10n.inquiry_title_hint,
                maxLength: 100,
                showCharacterCount: true),
            const SizedBox(height: 24),
            Text(context.l10n.inquiry_content, style: context.h6_700Style),
            const SizedBox(height: 8),
            CommonTextFormField(
              controller: _contentController,
              hintText: context.l10n.inquiry_content_hint,
              maxLines: 8,
              maxLength: 1000,
              showCharacterCount: true,
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? context.l10n.inquiry_content_required
                  : null,
            ),
            const SizedBox(height: 32),
            CommonElevatedButton(
              isExpandedWidth: true,
              isLoading: state.isInquirySubmitting,
              onPressed: state.isInquirySubmitting
                  ? null
                  : () => _onSubmitInquiry(context),
              text: context.l10n.inquiry_submit,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _onSubmitInquiry(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final userId = getIt<GlobalBloc>().state.user?.id;
    if (userId == null) {
      bloc.addToastMessage(context.l10n.inquiry_login_required);
      return;
    }

    bloc.add(MyEvent.submitInquiryRequested(
      userId: userId,
      category: bloc.state.selectedCategory,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
    ));
  }

  String _categoryLabel(InquiryCategory category) {
    switch (category) {
      case InquiryCategory.bug:
        return context.l10n.inquiry_category_error;
      case InquiryCategory.featureRequest:
        return context.l10n.inquiry_category_suggestion;
      case InquiryCategory.etc:
        return context.l10n.category_other;
    }
  }
}
