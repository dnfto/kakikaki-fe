import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/context_extension.dart';
import 'package:kakikaki/core/utils/formatter_utils.dart';
import 'package:flutter/material.dart';

class CommonDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? hintText;
  final bool? useEmpty;
  final Color? borderColor;
  CommonDatePicker({
    super.key,
    required this.controller,
    this.focusNode,
    this.hintText,
    this.useEmpty = false,
    this.borderColor,
  }) {
    // Set the default value to today's date
    if (useEmpty == false) {
      controller.text = controller.text.isNotEmpty
          ? controller.text
          : DateTimeFormatter.dateFormatHyphen.format(DateTime.now());
    }
  }

  @override
  Widget build(BuildContext context) {
    final finalBorderColor = borderColor ?? context.palette.primary;

    Future<void> selectDate(BuildContext context) async {
      // Trigger the date picker on tap
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: controller.text.isEmpty
            ? DateTime.now()
            : DateTimeFormatter.dateFormatHyphen.parse(controller.text),
        firstDate: DateTime(2000),
        lastDate: DateTime(2101),
      );
      if (pickedDate != null) {
        controller.text = DateTimeFormatter.dateFormatHyphen.format(pickedDate);
      }
    }

    return GestureDetector(
      onTap: () async {
        await selectDate(context);
      },
      child: AbsorbPointer(
        child: SizedBox(
          height: 40, // 드롭다운과 같은 높이
          child: TextField(
            readOnly: true,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            controller: controller,
            style: context.h6_400Style,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: 40 * 0.2, // 드롭다운과 동일한 패딩 계산
                horizontal: 12,
              ),
              hintText: hintText ?? "",
              hintStyle: context.h6_400Style.copyWith(
                color: Palette.gray50,
              ),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: finalBorderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: finalBorderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: finalBorderColor),
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.calendar_month,
                  size: 16, // 드롭다운 아이콘과 비슷한 크기
                  color: Palette.gray50,
                ),
                onPressed: () async {
                  await selectDate(context);
                },
              ),
              suffixIconConstraints: BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
