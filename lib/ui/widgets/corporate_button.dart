import 'package:flutter/material.dart';

const _brandGreen = Color(0xFF0C4F31);

class CorporateButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool enabled;
  final IconData? icon;
  final double height;
  final double borderRadius;

  const CorporateButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.height = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          elevation: 2,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        onPressed: enabled ? onPressed : null,
        child: icon == null
            ? Text(text)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(text),
                ],
              ),
      ),
    );
  }
}
