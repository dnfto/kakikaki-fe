import 'package:flutter/material.dart';
import 'package:kakikaki/app/constants/palette.dart';
import 'package:kakikaki/app/widget/bottom_sheet/common_bottom_sheet.dart';
import 'package:kakikaki/app/widget/button/common_elevated_button.dart';
import 'package:kakikaki/app/widget/button/common_outlined_button.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:kakikaki/core/utils/formatter_utils.dart';

Future<String?> showCreateFolderNameSheet({
  required BuildContext context,
  required String title,
  required String hintText,
  required String cancelText,
  required String createText,
  int maxLength = 50,
}) {
  return context.showModalCommonBottomSheet<String>(
    CommonBottomSheet(
      isDragHandle: true,
      child: _CreateFolderNameSheetContent(
        title: title,
        hintText: hintText,
        cancelText: cancelText,
        createText: createText,
        maxLength: maxLength,
      ),
    ),
  );
}

class _CreateFolderNameSheetContent extends StatefulWidget {
  const _CreateFolderNameSheetContent({
    required this.title,
    required this.hintText,
    required this.cancelText,
    required this.createText,
    required this.maxLength,
  });

  final String title;
  final String hintText;
  final String cancelText;
  final String createText;
  final int maxLength;

  @override
  State<_CreateFolderNameSheetContent> createState() =>
      _CreateFolderNameSheetContentState();
}

class _CreateFolderNameSheetContentState
    extends State<_CreateFolderNameSheetContent> {
  String _inputText = '';

  @override
  void initState() {
    super.initState();
  }

  void _submit() {
    final text = _inputText.trim();
    Navigator.of(context, rootNavigator: true).pop(text.isEmpty ? null : text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: context.screenWidth * 0.05),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: context.h5_700Style),
          const SizedBox(height: 12),
          TextField(
            autofocus: false,
            maxLength: widget.maxLength,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.done,
            inputFormatters: [InputFormatters.noLeadingWhitespace],
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            onChanged: (value) => _inputText = value,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: widget.hintText,
              counterText: '',
              filled: true,
              fillColor: Palette.gray10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: context.palette.primary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CommonOutlinedButton(
                  height: 40,
                  foregroundColor: Palette.gray30,
                  textColor: context.palette.primary,
                  label: widget.cancelText,
                  onPressed: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CommonElevatedButton(
                  height: 40,
                  text: widget.createText,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
