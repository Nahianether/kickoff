import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An animated football (soccer ball) used as the app's loading indicator:
/// the ball spins continuously while bouncing, with a soft shadow that reacts
/// to its height.
class FootballLoader extends StatefulWidget {
  const FootballLoader({super.key, this.size = 44});

  final double size;

  @override
  State<FootballLoader> createState() => _FootballLoaderState();
}

class _FootballLoaderState extends State<FootballLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.size;
    final amplitude = size * 0.85;

    return SizedBox(
      width: size * 1.8,
      height: size * 2.1,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Smooth single bounce per cycle: 0 (ground) → 1 (apex) → 0.
          final lift = (1 - math.cos(t * 2 * math.pi)) / 2;
          final grounded = 1 - lift; // 1 when resting on the ground
          final dy = -amplitude * lift;

          return Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Shadow: wider & darker when the ball is grounded.
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  width: size * (0.45 + 0.45 * grounded),
                  height: size * 0.14,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.10 + 0.14 * grounded),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              // Ball: lifts, spins, and squashes slightly on landing.
              Transform.translate(
                offset: Offset(0, dy),
                child: Transform.rotate(
                  angle: t * 2 * math.pi,
                  child: Transform.scale(
                    scaleX: 1 + 0.08 * grounded,
                    scaleY: 1 - 0.08 * grounded,
                    child: Icon(
                      Icons.sports_soccer,
                      size: size,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Centered football loader with an optional caption — used for full-screen
/// loading states.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FootballLoader(),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
