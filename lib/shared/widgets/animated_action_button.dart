import 'package:flutter/material.dart';

class AnimatedActionButton extends StatefulWidget {
  const AnimatedActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.expand = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool expand;

  @override
  State<AnimatedActionButton> createState() => _AnimatedActionButtonState();
}

class _AnimatedActionButtonState extends State<AnimatedActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = true),
      onPointerUp: widget.onPressed == null
          ? null
          : (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: SizedBox(
          width: widget.expand ? double.infinity : null,
          child: FilledButton.icon(
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, size: 18),
            label: Text(
              widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}
