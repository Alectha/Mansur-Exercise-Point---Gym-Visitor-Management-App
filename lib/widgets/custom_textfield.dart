import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Masukkan $label',
        prefixIcon:
            icon != null ? Icon(icon, color: const Color(0xFF4FC3F7)) : null,
      ),
    );
  }
}
