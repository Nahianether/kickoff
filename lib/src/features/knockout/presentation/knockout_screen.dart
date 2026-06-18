import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_error.dart';
import '../../../core/widgets/football_loader.dart';
import '../../competitions/competitions_providers.dart';
import '../../competitions/data/competition.dart';
import '../../competitions/presentation/league_app_bar.dart';
import '../../matches/data/models/match_fixture.dart';
import '../../matches/presentation/match_detail_screen.dart';
import '../../matches/presentation/widgets/team_crest.dart';
import '../../matches/providers.dart';
import '../knockout_providers.dart';

/// The knockout bracket: a horizontally-scrolling tournament tree where each
/// round's matches are vertically centred across a shared height and connected
/// to the next round with elbow lines.
class KnockoutScreen extends ConsumerWidget {
  const KnockoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knockout = ref.watch(knockoutProvider);

    return Scaffold(
      appBar: const LeagueAppBar(),
      body: RefreshIndicator(
        onRefresh: () => ref.read(matchesProvider.notifier).refresh(),
        child: knockout.when(
          loading: () => const AppLoader(message: 'Loading bracket…'),
          error: (err, _) => ListView(children: [
            const SizedBox(height: 120),
            Center(
                child: Text('Could not load bracket.\n${friendlyError(err)}',
                    textAlign: TextAlign.center)),
          ]),
          data: (rounds) {
            if (rounds.isEmpty) return const _EmptyBracket();
            return _Bracket(rounds: rounds);
          },
        ),
      ),
    );
  }
}

class _EmptyBracket extends StatelessWidget {
  const _EmptyBracket();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        const SizedBox(height: 100),
        Icon(Icons.account_tree_outlined,
            size: 48, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(height: 16),
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'The knockout bracket appears once the group stage is complete.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      ],
    );
  }
}

/// Bracket layout geometry. A round with N matches is spread evenly across the
/// same total height as the first round, so each match centres between the two
/// that feed it.
class _Geo {
  static const double cardWidth = 212;
  static const double cardHeight = 92;
  static const double colGap = 40; // horizontal room for connector elbows
  static const double rowGap = 16; // vertical gap between first-round cards
  static const double headerHeight = 34;

  /// Pitch (centre-to-centre spacing) of the first round.
  static const double unit = cardHeight + rowGap;

  static double columnX(int round) => round * (cardWidth + colGap);
}

/// Timeline shared by the entrance animation: each round's cards (and the
/// connectors leading into it) reveal a little after the previous round, so the
/// bracket appears to "build" left-to-right.
const double _kStagger = 0.10;
const double _kWindow = 0.5;

Interval _revealInterval(int round) {
  final start = (round * _kStagger).clamp(0.0, 1.0 - _kWindow);
  return Interval(start, start + _kWindow, curve: Curves.easeOutCubic);
}

class _Bracket extends ConsumerStatefulWidget {
  const _Bracket({required this.rounds});

  final List<KnockoutRound> rounds;

  @override
  ConsumerState<_Bracket> createState() => _BracketState();
}

class _BracketState extends ConsumerState<_Bracket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rounds = widget.rounds;
    final theme = Theme.of(context);
    final competition = ref.watch(selectedCompetitionProvider);

    final firstCount = rounds.first.matches.length.clamp(1, 1 << 30);
    final totalHeight = _Geo.unit * firstCount;
    final totalWidth = rounds.length * _Geo.cardWidth +
        (rounds.length - 1) * _Geo.colGap;

    // Centre of match [i] in round [r], in the shared coordinate space.
    double centerY(int round, int index) {
      final count = rounds[round].matches.length;
      final pitch = totalHeight / count;
      return pitch * (index + 0.5);
    }

    final cards = <Widget>[];
    for (var r = 0; r < rounds.length; r++) {
      final matches = rounds[r].matches;
      for (var i = 0; i < matches.length; i++) {
        cards.add(Positioned(
          left: _Geo.columnX(r),
          top: centerY(r, i) - _Geo.cardHeight / 2,
          width: _Geo.cardWidth,
          height: _Geo.cardHeight,
          child: _Reveal(
            animation: _entrance,
            interval: _revealInterval(r),
            child: _MatchCard(match: matches[i], competition: competition),
          ),
        ));
      }
    }

    return ListView(
      // Keep pull-to-refresh working; the bracket scrolls horizontally inside.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderRow(rounds: rounds),
                const SizedBox(height: 6),
                SizedBox(
                  width: totalWidth,
                  height: totalHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _ConnectorPainter(
                            rounds: rounds,
                            totalHeight: totalHeight,
                            color: theme.colorScheme.outlineVariant,
                            animation: _entrance,
                          ),
                        ),
                      ),
                      ...cards,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Fades, slides and scales [child] in over its round's slice of the timeline.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.animation,
    required this.interval,
    required this.child,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = interval.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset((1 - t) * -22, 0),
            child: Transform.scale(scale: 0.94 + 0.06 * t, child: child),
          ),
        );
      },
    );
  }
}

/// The round titles, aligned above their columns and scrolling with them.
class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.rounds});

  final List<KnockoutRound> rounds;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _Geo.headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var r = 0; r < rounds.length; r++) ...[
            SizedBox(
              width: _Geo.cardWidth,
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      rounds[r].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${rounds[r].matches.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (r != rounds.length - 1) const SizedBox(width: _Geo.colGap),
          ],
        ],
      ),
    );
  }
}

/// Draws the elbow connectors between each round and the next, but only where
/// the next round has exactly half the matches (a clean binary step) and isn't
/// the standalone third-place game.
class _ConnectorPainter extends CustomPainter {
  _ConnectorPainter({
    required this.rounds,
    required this.totalHeight,
    required this.color,
    required this.animation,
  }) : super(repaint: animation);

  final List<KnockoutRound> rounds;
  final double totalHeight;
  final Color color;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var r = 0; r < rounds.length - 1; r++) {
      final from = rounds[r];
      final to = rounds[r + 1];
      if (from.stage == 'THIRD_PLACE' || to.stage == 'THIRD_PLACE') continue;
      // Only connect clean binary steps (e.g. 8 → 4); skip irregular rounds.
      if (to.matches.length * 2 != from.matches.length) continue;

      // Reveal each connector in step with the column it leads into; draw the
      // elbow progressively (feeder → join → parent) so the lines "grow" in.
      final t = _revealInterval(r + 1).transform(animation.value);
      if (t <= 0) continue;
      paint.color = color.withValues(alpha: t);

      final fromPitch = totalHeight / from.matches.length;
      final toPitch = totalHeight / to.matches.length;
      final fromRightX = _Geo.columnX(r) + _Geo.cardWidth;
      final toLeftX = _Geo.columnX(r + 1);
      final midX = fromRightX + _Geo.colGap / 2;

      for (var j = 0; j < to.matches.length; j++) {
        final topFeederY = fromPitch * (2 * j + 0.5);
        final botFeederY = fromPitch * (2 * j + 1.5);
        final parentY = toPitch * (j + 0.5);

        // Two short stubs out of the feeders, a vertical join, then into parent,
        // each scaled by [t] from its start point so the elbow draws itself.
        canvas.drawLine(Offset(fromRightX, topFeederY),
            Offset.lerp(Offset(fromRightX, topFeederY), Offset(midX, topFeederY), t)!, paint);
        canvas.drawLine(Offset(fromRightX, botFeederY),
            Offset.lerp(Offset(fromRightX, botFeederY), Offset(midX, botFeederY), t)!, paint);
        canvas.drawLine(Offset(midX, topFeederY),
            Offset.lerp(Offset(midX, topFeederY), Offset(midX, botFeederY), t)!, paint);
        canvas.drawLine(Offset(midX, parentY),
            Offset.lerp(Offset(midX, parentY), Offset(toLeftX, parentY), t)!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ConnectorPainter old) =>
      old.rounds != rounds ||
      old.totalHeight != totalHeight ||
      old.color != color;
}

class _MatchCard extends StatefulWidget {
  const _MatchCard({required this.match, required this.competition});

  final MatchFixture match;
  final Competition competition;

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard> {
  bool _hover = false;

  MatchFixture get match => widget.match;

  bool _isWinner(bool home) {
    if (!match.isFinished) return false;
    if (match.score.winner == 'HOME_TEAM') return home;
    if (match.score.winner == 'AWAY_TEAM') return !home;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedScale(
        scale: _hover ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Material(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
          elevation: _hover ? 6 : 0,
          shadowColor: Colors.black,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MatchDetailScreen(
                    match: match, competition: widget.competition),
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hover ? scheme.primary : scheme.outlineVariant,
                  width: _hover ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    match.isFinished
                        ? 'Full-time'
                        : DateFormat('EEE, d MMM · h:mm a')
                            .format(match.utcDate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _teamLine(theme, match.homeTeam, match.score.homeFullTime,
                      _isWinner(true)),
                  const SizedBox(height: 5),
                  _teamLine(theme, match.awayTeam, match.score.awayFullTime,
                      _isWinner(false)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _teamLine(ThemeData theme, team, int? goals, bool winner) {
    return Row(
      children: [
        TeamCrest(team: team, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            team.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: winner ? FontWeight.w700 : FontWeight.w500,
              color: winner ? theme.colorScheme.onSurface : null,
            ),
          ),
        ),
        if (goals != null) ...[
          const SizedBox(width: 6),
          Text(
            '$goals',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: winner ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
