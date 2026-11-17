import 'dart:convert';

class FplTeam {
  final String id;
  final String profileId;
  final String name;
  final String? owner;
  final int budget;
  final String? iplTeamId;
  final List<String> startingXi;
  final List<String> substitutes;
  final String? captain;
  final String? viceCaptain;
  final Map<String, dynamic> chips;
  final int sortOrder;

  FplTeam({
    required this.id,
    required this.profileId,
    required this.name,
    this.owner,
    required this.budget,
    this.iplTeamId,
    required this.startingXi,
    required this.substitutes,
    this.captain,
    this.viceCaptain,
    required this.chips,
    this.sortOrder = 0,
  });

  factory FplTeam.fromJson(Map<String, dynamic> json) {
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

    Map<String, dynamic> parseMap(dynamic val) {
      if (val == null) return {};
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is String) {
        try {
          final decoded = jsonDecode(val);
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      return {};
    }

    return FplTeam(
      id: json['id']?.toString() ?? '',
      profileId: json['profile_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      owner: json['owner']?.toString(),
      budget: int.tryParse(json['budget']?.toString() ?? '1000') ?? 1000,
      iplTeamId: json['ipl_team_id']?.toString(),
      startingXi: parseList(json['starting_xi']),
      substitutes: parseList(json['substitutes']),
      captain: json['captain']?.toString(),
      viceCaptain: json['vice_captain']?.toString(),
      chips: parseMap(json['chips']),
      sortOrder: int.tryParse(json['sort_order']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'name': name,
      'owner': owner,
      'budget': budget,
      'ipl_team_id': iplTeamId,
      'starting_xi': jsonEncode(startingXi),
      'substitutes': jsonEncode(substitutes),
      'captain': captain,
      'vice_captain': viceCaptain,
      'chips': jsonEncode(chips),
      'sort_order': sortOrder,
    };
  }
}

