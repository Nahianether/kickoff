/// Whether a competition is a straight league table or a cup with a knockout
/// stage (which unlocks the Bracket tab).
enum CompetitionType { league, cup }

/// A football competition supported by the app: its football-data.org code plus
/// the metadata needed to present it (name, country, emblem).
class Competition {
  /// football-data.org competition code, e.g. "PL", "CL".
  final String code;
  final String name;
  final String shortName;
  final String country;
  final CompetitionType type;

  /// Crest/emblem URL, or null when none is available (e.g. World Cup).
  final String? emblemUrl;

  const Competition({
    required this.code,
    required this.name,
    required this.shortName,
    required this.country,
    required this.type,
    this.emblemUrl,
  });

  /// True for cup competitions, which have a knockout bracket.
  bool get hasKnockout => type == CompetitionType.cup;

  static const premierLeague = Competition(
    code: 'PL',
    name: 'Premier League',
    shortName: 'Premier League',
    country: 'England',
    type: CompetitionType.league,
    emblemUrl: 'https://crests.football-data.org/PL.png',
  );

  static const laLiga = Competition(
    code: 'PD',
    name: 'La Liga',
    shortName: 'La Liga',
    country: 'Spain',
    type: CompetitionType.league,
    emblemUrl: 'https://crests.football-data.org/PD.png',
  );

  static const serieA = Competition(
    code: 'SA',
    name: 'Serie A',
    shortName: 'Serie A',
    country: 'Italy',
    type: CompetitionType.league,
    emblemUrl: 'https://crests.football-data.org/SA.png',
  );

  static const bundesliga = Competition(
    code: 'BL1',
    name: 'Bundesliga',
    shortName: 'Bundesliga',
    country: 'Germany',
    type: CompetitionType.league,
    emblemUrl: 'https://crests.football-data.org/BL1.png',
  );

  static const ligue1 = Competition(
    code: 'FL1',
    name: 'Ligue 1',
    shortName: 'Ligue 1',
    country: 'France',
    type: CompetitionType.league,
    emblemUrl: 'https://crests.football-data.org/FL1.png',
  );

  static const championsLeague = Competition(
    code: 'CL',
    name: 'UEFA Champions League',
    shortName: 'Champions League',
    country: 'Europe',
    type: CompetitionType.cup,
    emblemUrl: 'https://crests.football-data.org/CL.png',
  );

  static const worldCup = Competition(
    code: 'WC',
    name: 'FIFA World Cup',
    shortName: 'World Cup',
    country: 'World',
    type: CompetitionType.cup,
    emblemUrl: null, // no emblem served; UI falls back to an icon
  );

  /// All competitions the app offers, in display order.
  static const all = <Competition>[
    premierLeague,
    laLiga,
    serieA,
    bundesliga,
    ligue1,
    championsLeague,
    worldCup,
  ];

  /// The default competition shown on first launch.
  static const Competition fallback = premierLeague;

  static Competition? byCode(String code) {
    for (final c in all) {
      if (c.code == code) return c;
    }
    return null;
  }
}
