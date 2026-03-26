import 'package:kakikaki/core/extension/extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class CommonAutoComplete<T extends Object> extends StatefulWidget {
  const CommonAutoComplete({
    super.key,
    required this.optionsBuilder,
    required this.onSubmitted,
    this.onSelected,

    /// Input view
    this.fieldKey,
    this.initialValue,
    this.onEditingEnd,
    this.hintText,

    /// Option view
    this.itemStyle,
    this.maxLines = 1,

    /// Event
    this.tapOptionSubmit = true, // Auto submit after selecting suggestion
    this.autoFillOption = true,

    // Buttons
    this.showSubButton = false,
    this.subLabel,
    this.onSubPressed,
    this.showSearchButton = false,
    this.onSearchPressed,
    this.searchLabel,
  });

  final AutocompleteOptionsBuilder<T> optionsBuilder;
  final ValueChanged<T> onSubmitted;
  final AutocompleteOnSelected<T>? onSelected;
  // Input view
  final GlobalKey<FormFieldState<String>>? fieldKey;
  final String? initialValue;
  final ValueChanged<String>? onEditingEnd;
  final String? hintText;

  // Option view
  final TextStyle? itemStyle;
  final int? maxLines;

  // Event
  final bool tapOptionSubmit;
  final bool autoFillOption;

  // Buttons
  final bool showSearchButton;
  final bool showSubButton;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onSubPressed;
  final String? searchLabel;
  final String? subLabel;

  @override
  State<CommonAutoComplete<T>> createState() => _CommonAutoCompleteState<T>();
}

class _CommonAutoCompleteState<T extends Object>
    extends State<CommonAutoComplete<T>> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double commonHeight = context.screenHeight * 0.06;

    return LayoutBuilder(builder: (context, BoxConstraints constraints) {
      return SizedBox(
        height: context.screenHeight * 0.06,
        child: Row(
          children: [
            Expanded(
              flex: 7,
              child: RawAutocomplete<T>(
                initialValue: (widget.initialValue == null)
                    ? null
                    : TextEditingValue(
                        text: widget.initialValue!,
                        selection: TextSelection.collapsed(
                            offset: widget.initialValue!.length),
                      ),
                focusNode: _focusNode,
                textEditingController: _textEditingController,
                onSelected: widget.onSelected,
                optionsBuilder: widget.optionsBuilder,
                optionsViewBuilder: (context, onSelected, options) =>
                    _optionsViewBuilder(
                        context, onSelected, options, constraints),
                fieldViewBuilder: _fieldViewBuilder,
              ),
            ),
            if (widget.showSearchButton)
              SizedBox(width: context.screenWidth * 0.02),
            if (widget.showSearchButton)
              SizedBox(
                height: commonHeight,
                // width: commonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onPressed: widget.onSearchPressed,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: widget.searchLabel != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search,
                                  color: context.palette.onPrimary),
                              Text(widget.searchLabel!,
                                  style: TextStyle(
                                      color: context.palette.onPrimary)),
                            ],
                          )
                        : Icon(Icons.search, color: context.palette.onPrimary),
                  ),
                ),
              ),
            if (widget.showSubButton)
              SizedBox(width: context.screenWidth * 0.02),
            if (widget.showSubButton)
              SizedBox(
                height: commonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.palette.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                  ),
                  onPressed: widget.onSubPressed,
                  child: widget.subLabel != null
                      ? FittedBox(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, color: context.palette.onPrimary),
                              Text(widget.subLabel!,
                                  style: TextStyle(
                                      color: context.palette.onPrimary)),
                            ],
                          ),
                        )
                      : Icon(Icons.add, color: context.palette.onPrimary),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _optionsViewBuilder(
      BuildContext context,
      AutocompleteOnSelected<T> onSelected,
      Iterable<T> options,
      BoxConstraints constraints) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        type: MaterialType.transparency,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: context.screenHeight * 0.3,
          ),
          child: Container(
            constraints: BoxConstraints(
              minHeight: context.screenHeight * 0.06,
              maxWidth: constraints.biggest.width,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.colorScheme.primary),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.primary.withExactOpacity(0.25),
                  blurRadius: 10,
                )
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: options.length,
              itemBuilder: (context, index) {
                return _optionsViewItemBuilder(
                  context,
                  index,
                  onSelected,
                  options,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _optionsViewItemBuilder(
    BuildContext context,
    int index,
    AutocompleteOnSelected<T> onSelected,
    Iterable<T> options,
  ) {
    final T option = options.elementAt(index);
    final bool highlight = AutocompleteHighlightedOption.of(context) == index;

    return InkWell(
      onTap: () {
        onSelected(option);
        if (widget.tapOptionSubmit) {
          FocusScope.of(context).unfocus();
          widget.onSubmitted(option);
        }
      },
      child: Container(
        color: highlight
            ? context.colorScheme.primary.withExactOpacity(0.5)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        alignment: Alignment.centerLeft,
        child: Builder(builder: (context) {
          if (highlight) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              Scrollable.ensureVisible(context, alignment: 0.5);
            });
          }
          return Text(
            RawAutocomplete.defaultStringForOption(option),
            // widget.displayStringForOption(option),
            style: widget.itemStyle ??
                context.h6_400Style
                    .copyWith(color: context.palette.onSurface, fontSize: 15),
            maxLines: widget.maxLines,
            overflow: TextOverflow.ellipsis,
          );
        }),
      ),
    );
  }

  //  Default UI search
  Widget _fieldViewBuilder(
      BuildContext context,
      TextEditingController textEditingController,
      FocusNode focusNode,
      VoidCallback onFieldSubmitted) {
    return SizedBox(
      height: context.screenHeight * 0.06,
      child: TextFormField(
        controller: _textEditingController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
              vertical: (context.screenHeight * 0.06 -
                      context.h6_400Style.fontSize!) /
                  2,
              horizontal: context.screenWidth * 0.02),
          counterText: '',
          border: OutlineInputBorder(
            borderSide: BorderSide(
                color: context.palette.primary.withExactOpacity(0.5),
                width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
                color: context.palette.primary.withExactOpacity(0.5),
                width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: context.palette.primary, width: 2.0),
            borderRadius: BorderRadius.circular(10.0),
          ),
          hintText: widget.hintText,
          hintStyle:
              context.h6_400Style.copyWith(color: context.palette.shadow),
          suffixIcon: IconButton(
            icon: Icon(
              Icons.clear,
              color: context.palette.primary,
            ),
            onPressed: () {
              textEditingController.clear();
            },
          ),
        ),
        onFieldSubmitted: (value) {
          if (value is T) {
            widget.onSubmitted(value as T);
          }
        },
      ),
    );
  }
}
