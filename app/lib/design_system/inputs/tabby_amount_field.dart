import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

/// Champ montant — décimales, suffixe devise, tokens [InputDecorationTheme].
class TabbyAmountField extends StatelessWidget {
  const TabbyAmountField({
    super.key,
    required this.controller,
    this.label,
    this.suffix = '€',
    this.autofocus = false,
    this.dense = false,
    this.textAlign = TextAlign.start,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.onFieldSubmitted,
    this.contentPadding,
  });

  final TextEditingController controller;
  final String? label;
  final String suffix;
  final bool autofocus;
  final bool dense;
  final TextAlign textAlign;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final EdgeInsetsGeometry? contentPadding;

  static final List<TextInputFormatter> formatters = [
    FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
  ];

  static double? parse(String text) =>
      double.tryParse(text.replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textAlign: textAlign,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: formatters,
      onChanged: onChanged,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        isDense: dense,
        contentPadding: contentPadding,
      ),
    );
  }
}
