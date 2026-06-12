import 'package:flutter/material.dart';

import '../../data/models/match_fixture.dart';

/// Small coloured pill describing a match's status (Live / Full-time / …).
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
      bg = Colors.red.shade600;
      fg = Colors.white;
    } else if (match.isFinished) {
      bg = scheme.surfaceContainerHighest;
      fg = scheme.onSurfaceVariant;
    } else {
      bg = scheme.secondaryContainer;
      fg = scheme.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (match.isLive) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
