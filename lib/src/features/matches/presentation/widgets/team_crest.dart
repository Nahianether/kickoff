import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/team.dart';

/// Shows a team's crest/flag from the network. football-data.org serves most
/// national-team crests as SVG and some as PNG, so we handle both, falling back
/// to the 3-letter country code when there's no image or it fails to load.
class TeamCrest extends StatelessWidget {
  const TeamCrest({super.key, required this.team, this.size = 40});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = team.crestUrl;
    if (url == null || url.isEmpty) return _fallback(context);

    final Widget image;
    if (url.toLowerCase().endsWith('.svg')) {
      image = SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => _fallback(context),
      );
    } else {
      image = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _fallback(context),
      );
    }

    // Clip flags to a rounded square so they sit consistently in the layout.
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.12),
      child: SizedBox(width: size, height: size, child: image),
    );
  }

  Widget _fallback(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Text(
        team.code,
        style: TextStyle(
          fontSize: size * 0.3,
          fontWeight: FontWeight.bold,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
