import 'package:flutter/material.dart';

/// A soft teal-glow gradient used as an app bar's `flexibleSpace` so headers
/// have depth instead of sitting flat on the background.
class HeaderGradient extends StatelessWidget {
  const HeaderGradient({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withValues(alpha: 0.16),
            scheme.surface.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}

/// App logo + wordmark used as a consistent app-bar title across screens.
class BrandTitle extends StatelessWidget {
  const BrandTitle({super.key, this.title = 'KickOff'});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo_new.png', height: 28, width: 28),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
        ),
      ],
    );
  }
}

/// Thin context/freshness strip shown below the app bar: a section label on the
/// left and an optional "Updated/Cached · Xm ago" indicator on the right.
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.label,
    this.updatedAt,
    this.cached = false,
  });

  final String label;
  final DateTime? updatedAt;
  final bool cached;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const Spacer(),
          if (updatedAt != null) _freshness(theme, scheme),
        ],
      ),
    );
  }

  Widget _freshness(ThemeData theme, ColorScheme scheme) {
    final color = cached ? const Color(0xFFE0A714) : scheme.primary;
    final text = cached
        ? 'Cached · ${relativeTimeLabel(updatedAt!)}'
        : 'Updated ${relativeTimeLabel(updatedAt!)}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

String relativeTimeLabel(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  return '${d.inDays}d ago';
}
