class Player {
  final String id;
  final String name;
  final String role;
  final String iplTeamId;
  final String tier;
  final int basePrice;
  final bool isOverseas;
  final bool isUncapped;
  final int totalPoints;
  final String? photoUrl;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.iplTeamId,
    required this.tier,
    required this.basePrice,
    required this.isOverseas,
    required this.isUncapped,
    required this.totalPoints,
    this.photoUrl,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'BAT',
      iplTeamId: json['ipl_team_id']?.toString() ?? '',
      tier: json['tier']?.toString() ?? 'Tier 3',
      basePrice: int.tryParse(json['base_price']?.toString() ?? '0') ?? 0,
      isOverseas: json['is_overseas'] == true || json['is_overseas'] == 1 || json['is_overseas'] == '1',
      isUncapped: json['is_uncapped'] == true || json['is_uncapped'] == 1 || json['is_uncapped'] == '1',
      totalPoints: int.tryParse(json['total_points']?.toString() ?? '0') ?? 0,
      photoUrl: json['photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'ipl_team_id': iplTeamId,
      'tier': tier,
      'base_price': basePrice,
      'is_overseas': isOverseas ? 1 : 0,
      'is_uncapped': isUncapped ? 1 : 0,
      'total_points': totalPoints,
      'photo_url': photoUrl,
    };
  }
}

