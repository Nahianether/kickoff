import '../../matches/data/models/team.dart';

/// One entry in a competition's top-scorers chart
/// (`/competitions/{code}/scorers`).
class Scorer {
  final int? playerId;
  final String playerName;
  final String? nationality;
  final Team team;
  final int goals;
  final int? assists;
  final int? penalties;
  final int? playedMatches;

  const Scorer({
    this.playerId,
    required this.playerName,
    this.nationality,
    required this.team,
    required this.goals,
    this.assists,
    this.penalties,
    this.playedMatches,
  });

  factory Scorer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>?;
    return Scorer(
      playerId: player?['id'] as int?,
      playerName: (player?['name'] ?? 'Unknown') as String,
      nationality: player?['nationality'] as String?,
      team: Team.fromJson(json['team'] as Map<String, dynamic>?),
      goals: (json['goals'] as int?) ?? 0,
      assists: json['assists'] as int?,
      penalties: json['penalties'] as int?,
      playedMatches: json['playedMatches'] as int?,
    );
  }
}
