import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class Input extends StatelessWidget {
  final TextEditingController controller;

  final bool? obscureText;
  final IconData? suffixIcon;
  final void Function()? onTapIcon;
  final String label;
  final bool disabled;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? prefixText;

  final List<TextInputFormatter>? inputFormatters;

  const Input({
    super.key,
    required this.controller,
    this.obscureText = false,
    this.inputFormatters,
    this.validator,
    this.suffixIcon,
    this.onTapIcon,
    required this.label,
    this.disabled = false,
    this.keyboardType,
    this.onChanged,
    this.prefixText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: TextFormField(
        onChanged: onChanged,
        enableInteractiveSelection: !disabled,
        keyboardType: keyboardType,
        validator: validator ?? generalValidator,
        controller: controller,
        readOnly: disabled,
        obscureText: obscureText ?? false,
        decoration: InputDecoration(
          prefixText: prefixText,
          suffixIcon: InkWell(onTap: onTapIcon, child: Icon(suffixIcon)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: inputFormatters,
      ),
    );
  }
}

String? generalValidator(String? value) {
  if (value == null || value.isEmpty) {
    return "Bu alan boş bırakılamaz";
  }

  return null;
}
