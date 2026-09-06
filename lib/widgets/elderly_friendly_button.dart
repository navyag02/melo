import 'package:flutter/material.dart';

/// ElderlyFriendlyButton is a reusable button component designed for elderly users
/// Features: large touch targets, high contrast, clear text, and generous padding
/// This widget should be used throughout the app for all primary actions
class ElderlyFriendlyButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? height;
  final bool isEnabled;

  const ElderlyFriendlyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = backgroundColor ?? const Color(0xFF4CAF50);
    final effectiveTextColor = textColor ?? Colors.white;
    final effectiveHeight = height ?? 70.0; // Default large height for elderly users

    return SizedBox(
      height: effectiveHeight,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBackgroundColor,
          foregroundColor: effectiveTextColor,
          disabledBackgroundColor: effectiveBackgroundColor.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: isEnabled ? 4 : 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 32,
                color: isEnabled ? effectiveTextColor : effectiveTextColor.withOpacity(0.5),
              ),
              const SizedBox(width: 16),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isEnabled ? effectiveTextColor : effectiveTextColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
