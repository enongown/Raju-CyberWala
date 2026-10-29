import 'package:flutter/material.dart';

/// Gentle staggered fade + rise for list items. Pass the item [index] so each
/// row starts a little after the previous one.
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.step = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 420),
    this.offsetY = 12,
  });

  final Widget child;
  final int index;
  final Duration step;
  final Duration duration;
  final double offsetY;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _a = CurvedAnimation(
    parent: _c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = widget.step * widget.index.clamp(0, 12);
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
  }
}
