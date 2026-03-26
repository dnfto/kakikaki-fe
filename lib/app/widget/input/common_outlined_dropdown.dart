import 'package:kakikaki/app/constants/constants.dart';
import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';

typedef ValueBuilder<T> = String Function(T item);
typedef ItemBuilder<T> = Widget Function(
    BuildContext context, T item, bool isSelected);

class CommonOutlinedDropdown<T> extends StatefulWidget {
  final List<T> items;
  final T? selectedItem;
  final ValueChanged<T> onItemSelected;
  final ValueBuilder<T> valueBuilder;
  final ItemBuilder<T>? itemBuilder;
  final Color? borderColor;
  final String? hintText;
  final double? height;
  final double? iconSize;
  final double? fontSize;

  const CommonOutlinedDropdown({
    super.key,
    required this.items,
    this.selectedItem,
    required this.onItemSelected,
    required this.valueBuilder,
    this.itemBuilder,
    this.borderColor,
    this.hintText,
    this.height,
    this.iconSize,
    this.fontSize,
  });

  @override
  CommonOutlinedDropdownState<T> createState() =>
      CommonOutlinedDropdownState<T>();
}

class CommonOutlinedDropdownState<T> extends State<CommonOutlinedDropdown<T>> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();
  bool _isDropdownOpened = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && !_isDropdownOpened) {
      _openDropdown();
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpened) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
    setState(() {}); // UI 다시 그리기
  }

  void _openDropdown() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      _isDropdownOpened = true;
    }
  }

  void _closeDropdown() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      _isDropdownOpened = false;
      setState(() {}); // UI 다시 그리기
    }
  }

  OverlayEntry _createOverlayEntry() {
    final borderColor = widget.borderColor ?? context.palette.primary;
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _closeDropdown, // 외부 클릭 시 드롭다운 닫기
          child: Container(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  width: size.width,
                  child: CompositedTransformFollower(
                    link: _layerLink,
                    showWhenUnlinked: false,
                    offset: Offset(0, size.height + 5),
                    child: Material(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: context.screenHeight * 0.3,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withExactOpacity(0.25),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            children: List.generate(
                              widget.items.length,
                              (index) {
                                T item = widget.items[index];
                                bool isSelected = item == widget.selectedItem;
                                return InkWell(
                                  onTap: () {
                                    widget.onItemSelected(item);
                                    _closeDropdown();
                                    _focusNode.unfocus();
                                  },
                                  child: Container(
                                    color: isSelected
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withExactOpacity(0.5)
                                        : null,
                                    padding: const EdgeInsets.all(10),
                                    child: Center(
                                      child: Text(
                                        widget.valueBuilder(item),
                                        style: context.h6_400Style.copyWith(
                                          color: context.palette.onSurface,
                                          fontSize: widget.fontSize,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.borderColor ?? context.palette.primary;

    return GestureDetector(
      onTap: _toggleDropdown,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: SizedBox(
          height: widget.height ?? 40,
          child: TextFormField(
            textAlign: TextAlign.left,
            focusNode: _focusNode,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                vertical: (widget.height ?? 40) * 0.2,
                horizontal: 12,
              ),
              suffixIcon: IconButton(
                icon: Transform.rotate(
                  angle: _isDropdownOpened ? -1.5708 : 1.5708, // 90도 회전 (상하 방향)
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Palette.gray50,
                    size: widget.iconSize ?? 16,
                  ),
                ),
                onPressed: _toggleDropdown,
              ),
              suffixIconConstraints: BoxConstraints(
                minWidth: 40,
                minHeight: 40,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderColor),
              ),
              hintText: widget.selectedItem == null ? widget.hintText : null,
              hintStyle: context.h6_400Style.copyWith(
                color: Palette.gray50,
              ),
            ),
            controller: TextEditingController(
              text: widget.selectedItem != null
                  ? widget.valueBuilder(widget.selectedItem!)
                  : '',
            ),
            readOnly: true,
            style: context.h6_400Style.copyWith(
              color: context.palette.onSurface,
              fontSize: widget.fontSize,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }
}
