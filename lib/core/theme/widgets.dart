import 'dart:ui';
import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Frosted glass card with backdrop blur
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? blurSigma;
  final double? opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blurSigma,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    final sigma = blurSigma ?? AppColors.glassBlurSigma;
    final bgOpacity = opacity ?? AppColors.glassOpacity;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassColor.withOpacity(bgOpacity),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.glassColor.withOpacity(AppColors.glassBorderOpacity),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Backward-compatible alias
typedef AppCard = GlassCard;

/// KYC/KYB status badge — glass-tinted
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.30)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// Full-width loading button with teal gradient
class LoadingButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;
  const LoadingButton(
      {super.key,
      required this.text,
      required this.loading,
      this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;
    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : AppColors.primary.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}

/// Skeleton loading placeholder — glass shimmer
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const SkeletonBox({super.key, required this.width, required this.height});

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}
