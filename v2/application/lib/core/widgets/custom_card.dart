import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Neumorphic Soft UI rounded container card with dual bevel shadows.
class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final List<BoxShadow>? customShadows;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.borderRadius = 20,
    this.customShadows,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 0.8),
        boxShadow: customShadows ?? AppColors.neumorphicShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
