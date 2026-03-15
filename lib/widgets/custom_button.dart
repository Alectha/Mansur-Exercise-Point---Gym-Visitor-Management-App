import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final double? width;
  final Color? color;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF2c3e50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
