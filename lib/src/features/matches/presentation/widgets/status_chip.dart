import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/match_fixture.dart';

/// Small coloured pill describing a match's status (Live / Full-time / …).
/// Live matches get a gently pulsing dot to draw the eye.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.match});

  final MatchFixture match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = match.status.label;
    if (label.isEmpty) return const SizedBox.shrink();

    Color bg;
    Color fg;
    if (match.isLive) {
      bg = AppTheme.live.withValues(alpha: 0.16);
      fg = AppTheme.live;
    } else if (match.isFinished) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    } else {
      bg = scheme.primary.withValues(alpha: 0.14);
      fg = scheme.primary;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(match.isLive ? 8 : 9, 4, 9, 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive) ...[
            const _PulsingDot(color: AppTheme.live),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small dot that softly pulses — used to signal a live match.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});

  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5 * (1 - t)),
                blurRadius: 2 + 4 * t,
                spreadRadius: 1.5 * t,
              ),
            ],
          ),
        );
      },
    );
  }
}
