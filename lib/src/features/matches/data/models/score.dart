/// The score of a match (full-time and half-time), plus the winner.
class Score {
  final String? winner; // HOME_TEAM | AWAY_TEAM | DRAW | null
  final int? homeFullTime;
  final int? awayFullTime;
  final int? homeHalfTime;
  final int? awayHalfTime;

  const Score({
    this.winner,
    this.homeFullTime,
    this.awayFullTime,
    this.homeHalfTime,
    this.awayHalfTime,
  });

  factory Score.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Score();
    final fullTime = json['fullTime'] as Map<String, dynamic>?;
    final halfTime = json['halfTime'] as Map<String, dynamic>?;
    return Score(
      winner: json['winner'] as String?,
      homeFullTime: fullTime?['home'] as int?,
      awayFullTime: fullTime?['away'] as int?,
      homeHalfTime: halfTime?['home'] as int?,
      awayHalfTime: halfTime?['away'] as int?,
    );
  }

  bool get hasResult => homeFullTime != null && awayFullTime != null;

  bool get hasHalfTime => homeHalfTime != null && awayHalfTime != null;
}
