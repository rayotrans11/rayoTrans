import 'dart:ui';
import 'package:flutter/material.dart';

class RayoColors {
  static const Color primaryBlue = Color(0xFF0A84FF);
  static const Color successGreen = Color(0xFF30D158);
  static const Color warningOrange = Color(0xFFFF9F0A);
  static const Color dangerRed = Color(0xFFFF453A);
  static const Color truckCyan = Color(0xFF64D2FF);
  static const Color purple = Color(0xFFBF5AF2);
  static const Color indigo = Color(0xFF5E5CE6);
  static const Color gray = Color(0xFF8E8E93);

  static Color parseHex(String hex, {Color fallback = primaryBlue}) {
    try {
      String cleanHex = hex.replaceAll('#', '');
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }
}

class RayoBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const RayoBackground({super.key, required this.child, this.isDark = false});

  @override
  Widget build(BuildContext context) {
    final dark = isDark || Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base subtle gradient
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: dark
                  ? [
                      const Color(0xFF0B111E),
                      const Color(0xFF0D1B2A),
                      const Color(0xFF141F32),
                      const Color(0xFF080C14),
                    ]
                  : [
                      const Color(0xFFF2F5FB),
                      const Color(0xFFE4ECF8),
                      const Color(0xFFEDF3FC),
                      const Color(0xFFF8FAFC),
                    ],
            ),
          ),
        ),
        // Soft ambient blurred orbs for Apple Liquid Glass refraction
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (dark ? const Color(0xFF0A84FF) : const Color(0xFF3898FF))
                  .withValues(alpha: dark ? 0.18 : 0.14),
            ),
          ),
        ),
        Positioned(
          bottom: 100,
          left: -80,
          child: Container(
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (dark ? const Color(0xFF5E5CE6) : const Color(0xFF64D2FF))
                  .withValues(alpha: dark ? 0.15 : 0.12),
            ),
          ),
        ),
        // Glass blur backdrop filter
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: const SizedBox.expand(),
          ),
        ),
        child,
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? tintColor;
  final double blurAmount;
  final Border? customBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.cornerRadius = 24,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.tintColor,
    this.blurAmount = 24.0,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final defaultTint = isDark
        ? (tintColor != null
              ? tintColor!.withValues(alpha: 0.18)
              : const Color(0xFF1E293B).withValues(alpha: 0.55))
        : (tintColor != null
              ? tintColor!.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.68));

    final border =
        customBorder ??
        Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.8),
          width: 1.2,
        );

    final widgetBody = ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: defaultTint,
            borderRadius: BorderRadius.circular(cornerRadius),
            border: border,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF0A84FF).withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(cornerRadius),
          onTap: onTap,
          child: widgetBody,
        ),
      );
    }

    return widgetBody;
  }
}

class GlassEffectContainer extends StatelessWidget {
  final Widget child;
  final double spacing;
  final EdgeInsetsGeometry? padding;

  const GlassEffectContainer({
    super.key,
    required this.child,
    this.spacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(padding: padding, child: child);
  }
}
