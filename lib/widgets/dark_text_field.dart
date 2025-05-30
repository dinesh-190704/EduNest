import 'package:flutter/material.dart';

class DarkTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const DarkTextField({
    Key? key,
    this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(color: Colors.white), // Text color for dark backgrounds
      cursorColor: Colors.white, // Cursor color for dark backgrounds
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null
            ? IconTheme(
                data: const IconThemeData(color: Colors.white70),
                child: prefixIcon!,
              )
            : null,
        suffixIcon: suffixIcon != null
            ? IconTheme(
                data: const IconThemeData(color: Colors.white70),
                child: suffixIcon!,
              )
            : null,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red[300]!),
        ),
      ),
    );
  }
}
