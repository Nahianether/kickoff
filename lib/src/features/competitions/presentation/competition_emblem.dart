import 'package:flutter/material.dart';

import '../data/competition.dart';

/// Shows a competition's emblem from the network, falling back to a trophy icon
/// when there's no emblem URL (e.g. World Cup) or it fails to load.
class CompetitionEmblem extends StatelessWidget {
  const CompetitionEmblem({
    super.key,
    required this.competition,
    this.size = 40,
  });

  final Competition competition;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = competition.emblemUrl;
    if (url == null || url.isEmpty) return _fallback(context);
    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => _fallback(context),
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _fallback(context),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Icon(
      Icons.emoji_events_outlined,
      size: size * 0.82,
      color: scheme.primary,
    );
  }
}
