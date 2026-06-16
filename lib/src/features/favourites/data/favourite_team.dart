import '../../matches/data/models/team.dart';

/// A team the user has starred to follow. Stored locally (shared_preferences)
/// with just enough detail to render it anywhere without a network call.
class FavouriteTeam {
  final int id;
  final String name;
  final String? shortName;
  final String? tla;
  final String? crestUrl;

  /// The competition code the team was followed from (e.g. "PL", "PD"). Used to
  /// group followed teams by league. Empty for favourites saved before this was
  /// tracked.
  final String competitionCode;

  const FavouriteTeam({
    required this.id,
    required this.name,
    this.shortName,
    this.tla,
    this.crestUrl,
    this.competitionCode = '',
  });

  /// Builds a favourite from a match/standings [Team], tagged with the league it
  /// was followed from. Returns null for teams without an id (e.g. undecided
  /// knockout slots), which can't be followed.
  static FavouriteTeam? fromTeam(Team team, {String competitionCode = ''}) {
    final id = team.id;
    if (id == null) return null;
    return FavouriteTeam(
      id: id,
      name: team.name,
      shortName: team.shortName,
      tla: team.tla,
      crestUrl: team.crestUrl,
      competitionCode: competitionCode,
    );
  }

  /// A [Team] view of this favourite, so it can reuse team widgets (crest, etc).
  Team toTeam() => Team(
        id: id,
        name: name,
        shortName: shortName,
        tla: tla,
        crestUrl: crestUrl,
      );

  String get displayName => shortName ?? name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'tla': tla,
        'crest': crestUrl,
        'comp': competitionCode,
      };

  factory FavouriteTeam.fromJson(Map<String, dynamic> json) => FavouriteTeam(
        id: json['id'] as int,
        name: (json['name'] ?? 'Team') as String,
        shortName: json['shortName'] as String?,
        tla: json['tla'] as String?,
        crestUrl: json['crest'] as String?,
        competitionCode: (json['comp'] ?? '') as String,
      );
}
