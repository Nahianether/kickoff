import '../../matches/data/models/team.dart';

/// One team's row within a group standings table. Mutable while accumulating,
/// then sorted for display.
class StandingRow {
  final Team team;
  int played;
  int won;
  int drawn;
  int lost;
  int goalsFor;
  int goalsAgainst;

  StandingRow({
    required this.team,
    this.played = 0,
    this.won = 0,
    this.drawn = 0,
    this.lost = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
  });

  int get goalDifference => goalsFor - goalsAgainst;

  int get points => won * 3 + drawn;
}
