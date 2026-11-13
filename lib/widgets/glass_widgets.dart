import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';

class ResponsiveScaffold extends StatelessWidget {
  final Widget? drawer;
  final Widget body;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const ResponsiveScaffold({
    super.key,
    this.drawer,
    required this.body,
    this.floatingActionButton,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isWide = MediaQuery.of(context).size.width > 700;
    final bottomPadding = (!isLandscape && !isWide) ? 76.0 : 0.0;

    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      appBar: appBar,
      drawer: drawer,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive wide layout padding for landscape/iPad/iPhone Pro Max
            final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
            final isWide = constraints.maxWidth > 800;

            Widget content = Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: body,
            );

            if (isWide && isLandscape) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: content,
                ),
              );
            }
            return content;
          },
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class StatusPill extends StatelessWidget {
  final ParcelStatus status;
  final double fontSize;

  const StatusPill({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case ParcelStatus.registered:
        color = RayoColors.gray;
        icon = CupertinoIcons.tray;
        break;
      case ParcelStatus.loaded:
        color = RayoColors.indigo;
        icon = CupertinoIcons.archivebox;
        break;
      case ParcelStatus.inTransit:
        color = RayoColors.primaryBlue;
        icon = CupertinoIcons.bus;
        break;
      case ParcelStatus.outForDelivery:
        color = RayoColors.warningOrange;
        icon = CupertinoIcons.cart;
        break;
      case ParcelStatus.delivered:
        color = RayoColors.successGreen;
        icon = CupertinoIcons.checkmark_seal_fill;
        break;
      case ParcelStatus.failed:
        color = RayoColors.dangerRed;
        icon = CupertinoIcons.exclamationmark_triangle_fill;
        break;
      case ParcelStatus.returned:
        color = RayoColors.purple;
        icon = CupertinoIcons.arrow_uturn_left;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: fontSize + 2, color: color),
              const SizedBox(width: 5),
              Text(
                context.tr(status.translationKey),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TruckStatusPill extends StatelessWidget {
  final TruckStatus status;
  final double fontSize;

  const TruckStatusPill({
    super.key,
    required this.status,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case TruckStatus.available:
        color = RayoColors.successGreen;
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case TruckStatus.onRoute:
        color = RayoColors.truckCyan;
        icon = CupertinoIcons.compass;
        break;
      case TruckStatus.maintenance:
        color = RayoColors.warningOrange;
        icon = CupertinoIcons.wrench_fill;
        break;
      case TruckStatus.offline:
        color = RayoColors.gray;
        icon = CupertinoIcons.moon_fill;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: fontSize + 1, color: color),
          const SizedBox(width: 4),
          Text(
            context.tr(status.translationKey),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class GlassStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const GlassStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(CupertinoIcons.chevron_forward, size: 14, color: Colors.grey.withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final String? Function(String?)? validator;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      validator: validator,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[700],
          fontSize: 14,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
