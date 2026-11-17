class Gameweek {
  final String id;
  final String name;
  final int gameCount;
  final bool isActive;
  final bool isLocked;
  final String? lockTime;
  final String? startDate;
  final String? endDate;
  final int? number;
  final bool isComplete;

  Gameweek({
    required this.id,
    required this.name,
    required this.gameCount,
    required this.isActive,
    required this.isLocked,
    this.lockTime,
    this.startDate,
    this.endDate,
    this.number,
    required this.isComplete,
  });

  factory Gameweek.fromJson(Map<String, dynamic> json) {
    return Gameweek(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      gameCount: int.tryParse(json['game_count']?.toString() ?? '1') ?? 1,
      isActive: json['is_active'] == true || json['is_active'] == 1 || json['is_active'] == '1',
      isLocked: json['is_locked'] == true || json['is_locked'] == 1 || json['is_locked'] == '1',
      lockTime: json['lock_time']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      number: int.tryParse(json['number']?.toString() ?? ''),
      isComplete: json['is_complete'] == true || json['is_complete'] == 1 || json['is_complete'] == '1',
    );
  }
}

