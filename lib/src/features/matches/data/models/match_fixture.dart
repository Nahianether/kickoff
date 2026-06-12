import 'score.dart';
import 'team.dart';

enum MatchStatus {
  scheduled,
  timed,
  inPlay,
  paused,
  finished,
  postponed,
  suspended,
  cancelled,
  unknown;

  static MatchStatus fromApi(String? value) {
    switch (value) {
      case 'SCHEDULED':
        return MatchStatus.scheduled;
      case 'TIMED':
        return MatchStatus.timed;
      case 'IN_PLAY':
        return MatchStatus.inPlay;
      case 'PAUSED':
        return MatchStatus.paused;
      case 'FINISHED':
        return MatchStatus.finished;
      case 'POSTPONED':
        return MatchStatus.postponed;
      case 'SUSPENDED':
        return MatchStatus.suspended;
      case 'CANCELLED':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.unknown;
    }
  }

  String get label {
    switch (this) {
      case MatchStatus.scheduled:
      case MatchStatus.timed:
        return 'Upcoming';
      case MatchStatus.inPlay:
        return 'Live';
      case MatchStatus.paused:
        return 'Half-time';
      case MatchStatus.finished:
        return 'Full-time';
      case MatchStatus.postponed:
        return 'Postponed';
      case MatchStatus.suspended:
        return 'Suspended';
      case MatchStatus.cancelled:
        return 'Cancelled';
      case MatchStatus.unknown:
        return '';
    }
  }
}

/// A single World Cup match (fixture or result).
class MatchFixture {
  final int id;
  final DateTime utcDate;
  final MatchStatus status;
  final String stage; // GROUP_STAGE, LAST_16, ...
  final String? group; // GROUP_A ... or null for knockout
  final Team homeTeam;
  final Team awayTeam;
  final Score score;
  final String? venue;

  const MatchFixture({
    required this.id,
    required this.utcDate,
    required this.status,
    required this.stage,
    required this.group,
    required this.homeTeam,
    required this.awayTeam,
    required this.score,
    this.venue,
  });

  factory MatchFixture.fromJson(Map<String, dynamic> json) {
    return MatchFixture(
      id: json['id'] as int,
      utcDate: DateTime.parse(json['utcDate'] as String).toLocal(),
      status: MatchStatus.fromApi(json['status'] as String?),
      stage: (json['stage'] ?? 'GROUP_STAGE') as String,
      group: json['group'] as String?,
      homeTeam: Team.fromJson(json['homeTeam'] as Map<String, dynamic>?),
      awayTeam: Team.fromJson(json['awayTeam'] as Map<String, dynamic>?),
      score: Score.fromJson(json['score'] as Map<String, dynamic>?),
      venue: json['venue'] as String?,
    );
  }

  bool get isFinished => status == MatchStatus.finished;

  bool get isLive =>
      status == MatchStatus.inPlay || status == MatchStatus.paused;

  bool get isUpcoming =>
      status == MatchStatus.scheduled || status == MatchStatus.timed;

  /// "GROUP_STAGE" -> "Group Stage", "LAST_16" -> "Last 16".
  String get stageLabel => stage
      .split('_')
      .map((w) => w.isEmpty
          ? w
          : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
      .join(' ');

  /// "GROUP_A" -> "Group A".
  String? get groupLabel {
    if (group == null) return null;
    final parts = group!.split('_');
    if (parts.length < 2) return group;
    return 'Group ${parts.last.toUpperCase()}';
  }
}
