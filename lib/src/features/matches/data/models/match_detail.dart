/// A match official from `/matches/{id}` (referee, assistants, VAR).
class Referee {
  final String name;
  final String? role;
  final String? nationality;

  const Referee({required this.name, this.role, this.nationality});

  factory Referee.fromJson(Map<String, dynamic> json) => Referee(
        name: (json['name'] ?? 'Unknown') as String,
        role: json['type'] as String?,
        nationality: json['nationality'] as String?,
      );

  /// "REFEREE" -> "Referee", "ASSISTANT_REFEREE_N1" -> "Assistant Referee N1".
  String get roleLabel {
    final r = role;
    if (r == null || r.isEmpty) return 'Official';
    return r
        .split('_')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

/// Extra detail for a single match beyond what the fixtures list carries. Sourced
/// from `/matches/{id}` — only the fields available on the free tier are kept.
class MatchDetail {
  final int id;
  final int? matchday;
  final String? competitionName;
  final String? competitionEmblem;

  /// "REGULAR" | "EXTRA_TIME" | "PENALTY_SHOOTOUT" — how the result was decided.
  final String? duration;
  final DateTime? lastUpdated;
  final List<Referee> referees;

  const MatchDetail({
    required this.id,
    this.matchday,
    this.competitionName,
    this.competitionEmblem,
    this.duration,
    this.lastUpdated,
    this.referees = const [],
  });

  factory MatchDetail.fromJson(Map<String, dynamic> json) {
    final competition = json['competition'] as Map<String, dynamic>?;
    final score = json['score'] as Map<String, dynamic>?;
    final refs = (json['referees'] as List<dynamic>? ?? const [])
        .map((e) => Referee.fromJson(e as Map<String, dynamic>))
        .toList();
    final updated = json['lastUpdated'] as String?;
    return MatchDetail(
      id: json['id'] as int,
      matchday: json['matchday'] as int?,
      competitionName: competition?['name'] as String?,
      competitionEmblem: competition?['emblem'] as String?,
      duration: score?['duration'] as String?,
      lastUpdated: updated != null ? DateTime.tryParse(updated)?.toLocal() : null,
      referees: refs,
    );
  }

  /// The main referee, if present (other officials are assistants/VAR).
  Referee? get mainReferee {
    for (final r in referees) {
      if (r.role == 'REFEREE') return r;
    }
    return referees.isNotEmpty ? referees.first : null;
  }

  /// A human label for how the match was decided, or null for normal time.
  String? get durationLabel {
    switch (duration) {
      case 'EXTRA_TIME':
        return 'After extra time';
      case 'PENALTY_SHOOTOUT':
        return 'After penalties';
      default:
        return null;
    }
  }

  bool get hasExtraInfo =>
      matchday != null ||
      competitionName != null ||
      referees.isNotEmpty ||
      durationLabel != null;
}
