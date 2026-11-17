import 'dart:convert';

class Trade {
  final String id;
  final String profileId;
  final String fromTeamId;
  final String toTeamId;
  final List<String> playersFrom;
  final List<String> playersTo;
  final int moneyFrom;
  final int moneyTo;
  final String status;
  final String? type;
  final bool isPermanent;
  final String? gameweek;
  final String? createdAt;

  Trade({
    required this.id,
    required this.profileId,
    required this.fromTeamId,
    required this.toTeamId,
    required this.playersFrom,
    required this.playersTo,
    required this.moneyFrom,
    required this.moneyTo,
    required this.status,
    this.type,
    required this.isPermanent,
    this.gameweek,
    this.createdAt,
  });

  factory Trade.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val == null) return [];
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } catch (_) {}
      }
      return [];
    }

    return Trade(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      fromTeamId: json['from_team_id']?.toString() ?? '',
      toTeamId: json['to_team_id']?.toString() ?? '',
      playersFrom: parseList(json['players_from']),
      playersTo: parseList(json['players_to']),
      moneyFrom: int.tryParse(json['money_from']?.toString() ?? '0') ?? 0,
      moneyTo: int.tryParse(json['money_to']?.toString() ?? '0') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      type: json['type']?.toString(),
      isPermanent: json['is_permanent'] == true || json['is_permanent'] == 1 || json['is_permanent'] == '1',
      gameweek: json['gameweek']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}

