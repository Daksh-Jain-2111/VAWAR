import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, outline }

class ThemedButton extends StatelessWidget {
  final String title;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final EdgeInsets? padding;

  const ThemedButton({
    super.key,
    required this.title,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (variant) {
      case ButtonVariant.primary:
        backgroundColor = AppTheme.primaryGreen;
        textColor = Colors.white;
        borderColor = null;
        break;
      case ButtonVariant.secondary:
        backgroundColor = AppTheme.secondary;
        textColor = Colors.white;
        borderColor = null;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryGreen;
        borderColor = AppTheme.primaryGreen;
        break;
    }

    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: borderColor != null ? BorderSide(color: borderColor, width: 2) : BorderSide.none,
        ),
        elevation: variant == ButtonVariant.outline ? 0 : 2,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

