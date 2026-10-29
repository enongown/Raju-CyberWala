import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Soft illustrated "photo" used instead of network images so the app works
/// fully offline: a tinted sky, a sun and layered hills, plus an icon.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({
    super.key,
    required this.palette,
    this.icon,
    this.radius = 20,
    this.iconSize = 28,
    this.child,
  });

  /// Index into [palettes] (wraps around).
  final int palette;
  final IconData? icon;
  final double radius;
  final double iconSize;

  /// Optional overlay (e.g. initials or a favourite button).
  final Widget? child;

  static const palettes = <List<Color>>[
    // Morning blue
    [
      Color(0xFFD6E6FB),
      Color(0xFFEFF5FD),
      Color(0xFF7FA8E0),
      Color(0xFF3F74C4),
    ],
    // Sunset rose
    [
      Color(0xFFFBD9D3),
      Color(0xFFFEF0EC),
      Color(0xFFE59A8C),
      Color(0xFFB65A4B),
    ],
    // Valley green
    [
      Color(0xFFD5EEDB),
      Color(0xFFF0F8F1),
      Color(0xFF86C496),
      Color(0xFF3E8C55),
    ],
    // Dusk violet
    [
      Color(0xFFE3DDF6),
      Color(0xFFF4F1FC),
      Color(0xFFA696DA),
      Color(0xFF6650B0),
    ],
    // Golden hour
    [
      Color(0xFFFCEBC4),
      Color(0xFFFEF8E8),
      Color(0xFFE9BF62),
      Color(0xFFB0832A),
    ],
  ];

  static List<Color> colorsFor(int palette) =>
      palettes[palette % palettes.length];

  @override
  Widget build(BuildContext context) {
    final c = colorsFor(palette);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _HillsPainter(c)),
          if (icon != null)
            Positioned(
              left: 14,
              bottom: 14,
              child: Container(
                padding: EdgeInsets.all(iconSize * 0.32),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: c[3]),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.c);
  final List<Color> c;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [c[0], c[1]],
        ).createShader(rect),
    );
    // Sun
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.28),
      math.min(w, h) * 0.11,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    Path hills(double base, double amp, double phase, double freq) {
      final p = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 4) {
        final y =
            h * base -
            amp *
                h *
                (0.6 * math.sin(x / w * math.pi * freq + phase) +
                    0.4 * math.sin(x / w * math.pi * freq * 2.3 + phase * 1.7));
        p.lineTo(x, y);
      }
      p
        ..lineTo(w, h)
        ..close();
      return p;
    }

    canvas.drawPath(
      hills(0.55, 0.14, 0.4, 2.2),
      Paint()..color = c[2].withValues(alpha: 0.45),
    );
    canvas.drawPath(
      hills(0.70, 0.10, 2.1, 1.6),
      Paint()..color = c[2].withValues(alpha: 0.75),
    );
    canvas.drawPath(
      hills(0.86, 0.07, 4.0, 1.2),
      Paint()..color = c[3].withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_HillsPainter old) => old.c != c;
}

/// In-memory favourites (mock; not persisted).
final favouriteIds = ValueNotifier<Set<String>>(<String>{});

/// White circular heart button with a small pop animation.
class FavouriteButton extends StatelessWidget {
  const FavouriteButton({super.key, required this.id, this.size = 40});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: favouriteIds,
      builder: (context, ids, _) {
        final on = ids.contains(id);
        return Material(
          color: Colors.white.withValues(alpha: 0.92),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              final next = {...ids};
              on ? next.remove(id) : next.add(id);
              favouriteIds.value = next;
            },
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                  child: child,
                ),
                child: Icon(
                  on ? Icons.favorite : Icons.favorite_border,
                  key: ValueKey(on),
                  size: size * 0.5,
                  color: on ? AppColors.red : AppColors.text,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
