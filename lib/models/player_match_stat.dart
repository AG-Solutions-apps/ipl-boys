class PlayerMatchStat {
  final String id;
  final String playerId;
  final String gameweekId;
  final int matchNumber;
  final String profileId;
  final int points;
  final int runs;
  final int balls;
  final int wickets;
  final double oversBowled;
  final int runsConceded;
  final int catches;
  final int stumpings;
  final int runOuts;
  final bool teamWin;
  final bool motm;

  PlayerMatchStat({
    required this.id,
    required this.playerId,
    required this.gameweekId,
    required this.matchNumber,
    required this.profileId,
    required this.points,
    required this.runs,
    required this.balls,
    required this.wickets,
    required this.oversBowled,
    required this.runsConceded,
    required this.catches,
    required this.stumpings,
    required this.runOuts,
    required this.teamWin,
    required this.motm,
  });

  factory PlayerMatchStat.fromJson(Map<String, dynamic> json) {
    return PlayerMatchStat(
      id: json['id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      gameweekId: json['gameweek_id']?.toString() ?? '',
      matchNumber: int.tryParse(json['match_number']?.toString() ?? '0') ?? 0,
      profileId: json['profile_id']?.toString() ?? '',
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      runs: int.tryParse(json['runs']?.toString() ?? '0') ?? 0,
      balls: int.tryParse(json['balls']?.toString() ?? '0') ?? 0,
      wickets: int.tryParse(json['wickets']?.toString() ?? '0') ?? 0,
      oversBowled: double.tryParse(json['overs_bowled']?.toString() ?? '0.0') ?? 0.0,
      runsConceded: int.tryParse(json['runs_conceded']?.toString() ?? '0') ?? 0,
      catches: int.tryParse(json['catches']?.toString() ?? '0') ?? 0,
      stumpings: int.tryParse(json['stumpings']?.toString() ?? '0') ?? 0,
      runOuts: int.tryParse(json['run_outs']?.toString() ?? '0') ?? 0,
      teamWin: json['team_win'] == true || json['team_win'] == 1 || json['team_win'] == '1',
      motm: json['motm'] == true || json['motm'] == 1 || json['motm'] == '1',
    );
  }
}

