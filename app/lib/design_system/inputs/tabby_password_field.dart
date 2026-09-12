import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Champ mot de passe — toggle visibilité interne, tokens M3.
class TabbyPasswordField extends StatefulWidget {
  const TabbyPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.helperText,
    this.helperMaxLines,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final int? helperMaxLines;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<TabbyPasswordField> createState() => _TabbyPasswordFieldState();
}

class _TabbyPasswordFieldState extends State<TabbyPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperMaxLines: widget.helperMaxLines,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure
                ? Symbols.visibility_off_rounded
                : Symbols.visibility_rounded,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
