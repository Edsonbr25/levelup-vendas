import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class PremiumCard extends StatefulWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.glowColor = AppTheme.primary,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color glowColor;
  final VoidCallback? onTap;

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      scale: _pressed ? 0.985 : 1,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                _setPressed(false);
                widget.onTap?.call();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: _pressed ? 0.18 : 0.09,
                ),
                blurRadius: _pressed ? 28 : 18,
                spreadRadius: -10,
                offset: const Offset(0, 12),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.045),
                Colors.white.withValues(alpha: 0.012),
              ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }

  void _setPressed(bool value) {
    if (mounted) {
      setState(() => _pressed = value);
    }
  }
}
