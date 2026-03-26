import 'package:kakikaki/app/widget/widget.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

class CommonTextSearchField extends StatefulWidget {
  const CommonTextSearchField({
    super.key,
    required this.onFieldSubmitted,
    this.hintText,
    required this.controller,
    this.isBackButton = false,
    this.onPressedSuffixIcon,
    this.suffixIcon,
    this.onBackButtonPressed,
    this.subBtn = false,
    this.onPressedSubBtn,
    this.isSuffixButton = false,
    this.searchLabel,
    this.onChanged,
    this.subLabel,
    this.onFocusChanged,
    this.autofocus,
    this.focusNode,
  });

  final Function(String)? onChanged;
  final Function(String) onFieldSubmitted;
  final String? hintText;
  final TextEditingController controller;
  final bool isBackButton;
  final VoidCallback? onBackButtonPressed;
  final bool isSuffixButton;
  final String? suffixIcon;
  final Function()? onPressedSuffixIcon;
  final bool subBtn;
  final Function()? onPressedSubBtn;
  final String? searchLabel;
  final String? subLabel;
  final Function(bool)? onFocusChanged; // 포커스 변경 콜백
  final bool? autofocus;
  final FocusNode? focusNode;

  @override
  State<CommonTextSearchField> createState() => _CommonTextSearchFieldState();
}

class _CommonTextSearchFieldState extends State<CommonTextSearchField> {
  late FocusNode _focusNode; //  FocusNode 인스턴스

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      if (widget.onFocusChanged != null) {
        widget.onFocusChanged!(_focusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double commonHeight = context.screenHeight * 0.06;
    return Row(
      children: [
        if (widget.isBackButton)
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: context.palette.onSurface),
            padding: const EdgeInsets.all(10),
            onPressed:
                widget.onBackButtonPressed ?? () => Navigator.of(context).pop(),
          ),
        Expanded(
          child: SizedBox(
            height: commonHeight,
            child: TextField(
              style: context.h6_400Style
                  .copyWith(color: context.palette.onSurface),
              autofocus: widget.autofocus ?? false,
              focusNode: _focusNode,
              controller: widget.controller,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.symmetric(
                    vertical:
                        (commonHeight - context.h6_400Style.fontSize! * 1.5) /
                            2,
                    horizontal: context.screenWidth * 0.02),
                isDense: true,
                hintText: widget.hintText,
                suffixIcon: widget.isSuffixButton
                    ? widget.suffixIcon != null
                        ? CommonIcon.button(
                            widget.suffixIcon,
                            colorFilter:
                                CommonIcon.fillColor(context.palette.primary),
                            onPressed: widget.onPressedSuffixIcon,
                            padding: const EdgeInsets.all(8),
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.add, color: context.palette.primary),
                            padding: const EdgeInsets.all(8),
                            onPressed: widget.onPressedSuffixIcon,
                          )
                    : null,
                hintStyle:
                    context.h6_400Style.copyWith(color: context.palette.shadow),
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: context.palette.primary.withExactOpacity(0.5),
                      width: 2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: context.palette.primary.withExactOpacity(0.5),
                      width: 2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide:
                      BorderSide(color: context.palette.primary, width: 2),
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              // onSubmitted: widget.onFieldSubmitted,
              onChanged: widget.onChanged,
            ),
          ),
        ),
        SizedBox(width: context.screenWidth * 0.02),
        // 검색 버튼
        SizedBox(
          height: commonHeight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.palette.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0)),
            ),
            onPressed: () => widget.onFieldSubmitted(widget.controller.text),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: widget.searchLabel != null
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search, color: context.palette.onPrimary),
                        Text(widget.searchLabel!,
                            style: context.h6_400Style
                                .copyWith(color: context.palette.onPrimary)),
                      ],
                    )
                  : Icon(Icons.search, color: context.palette.onPrimary),
            ),
          ),
        ),
        // 서브 버튼
        if (widget.subBtn) SizedBox(width: context.screenWidth * 0.02),
        if (widget.subBtn)
          SizedBox(
            height: commonHeight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.palette.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
              ),
              onPressed: widget.onPressedSubBtn,
              child: widget.subLabel != null
                  ? FittedBox(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: context.palette.onPrimary),
                          Text(widget.subLabel!,
                              style: context.h6_400Style
                                  .copyWith(color: context.palette.onPrimary)),
                        ],
                      ),
                    )
                  : Icon(Icons.add, color: context.palette.onPrimary),
            ),
          ),
      ],
    );
  }
}
