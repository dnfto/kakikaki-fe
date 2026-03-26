import 'dart:async';
import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/context_extension.dart';
import 'package:flutter/material.dart';

/// 커스텀 TextField
class CommonTextFormField extends TextField {
  const CommonTextFormField({
    super.key,
    // Form
    this.fieldKey,
    this.initialValue,
    this.validator,
    this.onSaved,
    this.onFieldSubmitted,
    this.onEditingEnd,
    super.onEditingComplete,
    this.onFocusChange,
    // Text field
    super.controller,
    super.focusNode,
    super.keyboardType = TextInputType.text,
    super.textInputAction = TextInputAction.done,
    super.textCapitalization = TextCapitalization.sentences,
    super.style,
    super.textAlign = TextAlign.start,
    super.textAlignVertical = TextAlignVertical.center,
    super.textDirection,
    super.readOnly = false,
    super.showCursor = true,
    super.autofocus = false,
    super.autocorrect = true,
    super.obscureText = false,
    super.enableSuggestions = true,
    super.enabled,
    super.minLines,
    super.maxLength = 200,
    super.onChanged,
    super.inputFormatters,
    // Decoration
    this.fillColor,
    this.helperText,
    this.prefix,
    this.suffix,
    this.prefixIcon,
    this.label,
    this.hintText,
    this.hintStyle,
    this.errorText,
    this.suffixIcon,
    this.suffixIconConstraints,
    this.prefixIconConstraints,
    this.contentPadding,
    this.isDense,
    this.underlineColor,
    this.border,
    this.enabledBorder,
    this.disabledBorder,
    this.errorBorder,
    this.counterText,
    // Scroll
    super.expands = false,
    super.maxLines = 1,
    super.scrollController,
    super.scrollPhysics,
    this.enableInteractiveSelectionOption = true,
    super.onTap,
    this.showCharacterCount = false, // 글자 수 카운터 기본값 false
    this.characterCountStyle,
  });

  final InputBorder? border;
  final InputBorder? enabledBorder;
  final InputBorder? disabledBorder;
  final InputBorder? errorBorder;
  final String? counterText;

  /// 에러 텍스트가 없어도 빨간 테두리를 강제 적용할지 여부
  final Color? fillColor;
  final String? helperText;
  final Color? underlineColor;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffix;
  final Widget? suffixIcon;
  final Widget? label;
  final String? hintText;
  final TextStyle? hintStyle;
  final String? errorText;
  final BoxConstraints? suffixIconConstraints;
  final BoxConstraints? prefixIconConstraints;
  final EdgeInsets? contentPadding;
  // Form
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final String? initialValue;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onEditingEnd;
  final ValueChanged<bool>? onFocusChange;
  final bool? isDense;
  final bool enableInteractiveSelectionOption;
  // TextField
  final bool showCharacterCount; // 글자 수 카운터 표시 여부
  final TextStyle? characterCountStyle; // 글자 수 카운터 스타일

  @override
  State<CommonTextFormField> createState() => CommonTextFormFieldState();
}

class CommonTextFormFieldState extends State<CommonTextFormField>
    with TextFieldHandler {
  @override
  void initState() {
    super.initState();
    controller.addListener(_updateCharacterCount);
  }

  @override
  void dispose() {
    controller.removeListener(_updateCharacterCount);
    super.dispose();
  }

  // 글자 수 카운터 실시간 업데이트를 위한 메서드
  void _updateCharacterCount() {
    if (widget.showCharacterCount) {
      setState(() {}); // 글자 수 업데이트
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap:
              widget.readOnly && (widget.enabled ?? true) ? widget.onTap : null,
          child: AbsorbPointer(
            // readOnly일 때 텍스트 필드의 기본 입력 동작을 차단
            absorbing: widget.readOnly,
            child: TextFormField(
              key: fieldKey,
              focusNode: focusNode
                ..canRequestFocus = !widget.readOnly, // 포커스 차단
              controller: controller,
              obscureText: widget.obscureText,
              readOnly: widget.readOnly,
              showCursor: !widget.readOnly, // readOnly일 때 커서 비활성화
              onChanged: (value) {
                onFieldChange(value);
                if (widget.showCharacterCount) {
                  _updateCharacterCount(); // 실시간 업데이트
                }
              },
              decoration: buildDecoration(context),
              cursorColor: context.palette.primary,
              style: widget.style ?? context.h6_400Style,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              textCapitalization: widget.textCapitalization,
              onEditingComplete: widget.onEditingComplete,
              textAlign: widget.textAlign,
              textAlignVertical: widget.textAlignVertical,
              textDirection: widget.textDirection,
              autofocus: widget.autofocus,
              // autocorrect: widget.autocorrect,
              enableSuggestions: widget.enableSuggestions,
              enabled: widget.enabled,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              onFieldSubmitted: widget.onFieldSubmitted,
              inputFormatters: widget.inputFormatters,
              expands: widget.expands,
              maxLines: widget.maxLines,
              scrollController: widget.scrollController,
              scrollPhysics: widget.scrollPhysics,
              onSaved: widget.onSaved,
              validator: widget.validator,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              enableInteractiveSelection:
                  widget.enableInteractiveSelectionOption,
            ),
          ),
        ),
        if (widget.showCharacterCount)
          Positioned(
            bottom: 8,
            right: 16,
            child: Text(
              '${controller.text.length}/${widget.maxLength}',
              style: controller.text.isNotEmpty
                  ? widget.characterCountStyle ?? context.h6_400Style
                  : context.h6_400Style,
            ),
          ),
      ],
    );
  }

  InputDecoration buildDecoration(BuildContext context) {
    final double defaultPadding = 16;

    final hasError = widget.errorText != null ||
        widget.validator?.call(controller.text) != null;

    // 기본 둥근 테두리
    final InputBorder roundedBorder = OutlineInputBorder(
      borderRadius: Dimens.buttonRadius, // 기본 둥근 모서리 설정
      borderSide: BorderSide.none,
    );

    // Error 상태 테두리
    final InputBorder errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10.0),
      borderSide: BorderSide(
        color: widget.underlineColor ?? context.palette.error,
        width: 2.0,
      ),
    );

    return InputDecoration(
      counterStyle: widget.characterCountStyle ?? context.h6_400Style,
      enabled: widget.enabled ?? true,
      counterText: widget.counterText ?? "",
      contentPadding: widget.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefix: widget.prefix == null
          ? null
          : Padding(
              padding: EdgeInsets.only(left: defaultPadding),
              child: widget.prefix),
      prefixIcon: widget.prefixIcon,
      prefixIconConstraints: widget.prefixIconConstraints,
      suffix: widget.suffix,
      suffixIcon: widget.suffixIcon,
      suffixIconConstraints: widget.suffixIconConstraints,
      filled: true,
      isDense: widget.isDense,
      helperText: widget.helperText,
      helperStyle: context.h6_400Style.copyWith(color: context.palette.primary),
      fillColor: widget.fillColor ?? Palette.gray10,
      border: hasError
          ? (widget.errorBorder ?? errorBorder)
          : (widget.border ?? roundedBorder),

      enabledBorder: hasError
          ? (widget.errorBorder ?? errorBorder)
          : (widget.enabledBorder ?? roundedBorder),
      disabledBorder: widget.border ??
          widget.disabledBorder ??
          roundedBorder, // 비활성 상태 둥근 테두리
      errorBorder: widget.errorBorder ?? errorBorder, // 에러 상태 테두리
      focusedBorder: widget.readOnly // readOnly일 때 포커스 상태 테두리 변경
          ? widget.border ??
              roundedBorder.copyWith(
                borderSide: BorderSide.none,
              )
          : hasError
              ? widget.errorBorder ?? errorBorder // 에러 메시지가 있을 때는 에러 테두리 유지
              : widget.border ??
                  roundedBorder.copyWith(
                    borderSide: BorderSide(
                      color: context.palette.primary,
                      width: 2.0,
                    ),
                  ),
      hintText: widget.hintText,
      alignLabelWithHint: true, // 레이블과 에러 위치 일치
      hintStyle: widget.hintStyle ??
          context.h6_400Style.copyWith(color: Palette.gray50),
      errorText: (widget.errorText?.isEmpty ?? true)
          ? null // '' 또는 null이면 텍스트 출력 없이 테두리만 빨개짐
          : widget.errorText,
      errorStyle: context.h6_400Style.copyWith(color: context.palette.error),
      label: widget.label,
    );
  }
}

mixin TextFieldHandler on State<CommonTextFormField> {
  FocusNode? _focusNode;
  Timer? _debounce;
  GlobalKey<FormFieldState<String>>? fieldKey;
  TextEditingController? _controller;

  FocusNode get focusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  TextEditingController get controller =>
      widget.controller ??
      (_controller ??= TextEditingController(text: widget.initialValue));

  @override
  void initState() {
    fieldKey = widget.fieldKey ?? GlobalKey<FormFieldState<String>>();
    super.initState();
    focusNode.addListener(onFocusChange);
    controller.addListener(onControllerChange);
  }

  @override
  void dispose() {
    focusNode.removeListener(onFocusChange);
    controller.removeListener(onControllerChange);
    _focusNode?.dispose();
    _debounce?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void onFocusChange() {
    widget.onFocusChange?.call(focusNode.hasFocus);
  }

  void onControllerChange() {
    widget.onChanged?.call(controller.text);
  }

  void onFieldChange(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      widget.onEditingEnd?.call(value);
    });
  }
}
