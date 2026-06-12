/// A national team taking part in a match.
class Team {
  final int? id;
  final String name;
  final String? shortName;
  final String? tla; // 3-letter code, e.g. BRA
  final String? crestUrl;

  const Team({
    this.id,
    required this.name,
    this.shortName,
    this.tla,
    this.crestUrl,
  });

  /// Placeholder used for knockout slots that aren't decided yet.
  static const Team tbd = Team(name: 'TBD');

  factory Team.fromJson(Map<String, dynamic>? json) {
    if (json == null) return tbd;
    return Team(
      id: json['id'] as int?,
      name: (json['name'] ?? json['shortName'] ?? 'TBD') as String,
      shortName: json['shortName'] as String?,
      tla: json['tla'] as String?,
      crestUrl: json['crest'] as String?,
    );
  }

  String get displayName => shortName ?? name;

  String get code => tla ?? (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name);
}
