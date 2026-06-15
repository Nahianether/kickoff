import '../../matches/data/models/team.dart';

/// One team's row in a standings table, as returned by the API
/// (`/competitions/{code}/standings`).
class StandingRow {
  final int position;
  final Team team;
  final int played;
  final int won;
  final int drawn;
  final int lost;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;
  final int points;

  const StandingRow({
    required this.position,
    required this.team,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
    required this.points,
  });

  factory StandingRow.fromJson(Map<String, dynamic> json) {
    final gf = (json['goalsFor'] as int?) ?? 0;
    final ga = (json['goalsAgainst'] as int?) ?? 0;
    return StandingRow(
      position: (json['position'] as int?) ?? 0,
      team: Team.fromJson(json['team'] as Map<String, dynamic>?),
      played: (json['playedGames'] as int?) ?? 0,
      won: (json['won'] as int?) ?? 0,
      drawn: (json['draw'] as int?) ?? 0,
      lost: (json['lost'] as int?) ?? 0,
      goalsFor: gf,
      goalsAgainst: ga,
      goalDifference: (json['goalDifference'] as int?) ?? (gf - ga),
      points: (json['points'] as int?) ?? 0,
    );
  }
}

/// One table within a competition's standings: a plain league (no label), a
/// World Cup group ("Group A"), or the Champions League "League phase".
class StandingsTable {
  /// Display label, or null for a single league table that needs no heading.
  final String? label;
  final List<StandingRow> rows;

  const StandingsTable({required this.label, required this.rows});
}
