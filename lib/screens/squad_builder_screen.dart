import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fpl_team.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class SquadBuilderScreen extends StatefulWidget {
  final String? initialTeamId;

  const SquadBuilderScreen({super.key, this.initialTeamId});

  @override
  State<SquadBuilderScreen> createState() => _SquadBuilderScreenState();
}

class _SquadBuilderScreenState extends State<SquadBuilderScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;

  List<FplTeam> _teams = [];
  FplTeam? _selectedTeam;
  Map<String, Player> _playerMap = {};

  List<String> _startingXi = [];
  List<String> _substitutes = [];
  String? _captain;
  String? _viceCaptain;
  String? _activeGameweekId;
  String? _selectedChip;
  String? _chipTargetPlayerId;
  String? _chipTargetTeamId;
  int _requiredXiSize = 11;
  List<String> _enabledChips = [];
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _loans = [];
  List<String> _eligiblePlayerIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    var teams = await _api.getFplTeams(profileId: auth.activeProfileId);
    if (!auth.isAdmin && auth.currentUser?['id'] != null) {
      final assignments = await _api.queryTable('user_team_assignments', filters: {
        'user_id': auth.currentUser!['id'].toString(),
        'profile_id': auth.activeProfileId,
      });
      final teamIds = assignments.map((row) => (row as Map<String, dynamic>)['team_id']?.toString()).whereType<String>().toSet();
      teams = teams.where((team) => teamIds.contains(team.id)).toList();
    }
    final players = await _api.getPlayers();
    final gameweeks = await _api.getGameweeks();
    final profiles = await _api.queryTable('game_profiles', filters: {'id': auth.activeProfileId}, limit: 1);
    final assignments = await _api.queryTable('player_assignments', filters: {'profile_id': auth.activeProfileId});
    final loans = await _api.queryTable('player_loans', filters: {'profile_id': auth.activeProfileId});
    final config = profiles.isNotEmpty ? profiles.first as Map<String, dynamic> : <String, dynamic>{};
    dynamic rawChips = config['enabled_chips'];
    if (rawChips is String) {
      try { rawChips = jsonDecode(rawChips); } catch (_) { rawChips = []; }
    }
    final enabled = rawChips is List ? rawChips.map((chip) => chip.toString()).toList() : <String>[];
    final pMap = {for (var p in players) p.id: p};

    FplTeam? initialTeam;
    if (widget.initialTeamId != null && teams.isNotEmpty) {
      initialTeam = teams.firstWhere((t) => t.id == widget.initialTeamId, orElse: () => teams.first);
    } else if (teams.isNotEmpty) {
      initialTeam = teams.first;
    }

    if (mounted) {
      setState(() {
        _teams = teams;
        _playerMap = pMap;
        final activeWeeks = gameweeks.where((week) => week.isActive && !week.isLocked).toList();
        _activeGameweekId = activeWeeks.isEmpty ? null : activeWeeks.first.id;
        _requiredXiSize = activeWeeks.isNotEmpty && activeWeeks.first.number == 9 ? 5 : 11;
        _enabledChips = enabled;
        _assignments = assignments.cast<Map<String, dynamic>>();
        _loans = loans.cast<Map<String, dynamic>>();
        if (initialTeam != null) {
          _setTeam(initialTeam);
        }
        _isLoading = false;
      });
    }
  }

  void _setTeam(FplTeam team) {
    setState(() {
      _selectedTeam = team;
      _startingXi = List.from(team.startingXi);
      _substitutes = List.from(team.substitutes);
      final owned = _assignments.where((row) => row['fpl_team_id']?.toString() == team.id).map((row) => row['player_id']?.toString()).whereType<String>();
      final borrowed = _loans.where((row) => row['borrower_team_id']?.toString() == team.id && !(row['loan_returned'] == true || row['loan_returned'] == 1 || row['loan_returned'] == '1')).map((row) => row['player_id']?.toString()).whereType<String>();
      _eligiblePlayerIds = {...owned, ...borrowed}.toList();
      _captain = team.captain;
      _viceCaptain = team.viceCaptain;
      _selectedChip = null;
      _chipTargetPlayerId = null;
      _chipTargetTeamId = null;
      if (_activeGameweekId != null) {
        for (final entry in team.chips.entries) {
          final value = entry.value;
          if (value is Map && value['gameweek']?.toString() == _activeGameweekId && value['used'] == true) {
            _selectedChip = entry.key;
            _chipTargetPlayerId = value['targetPlayerId']?.toString();
            _chipTargetTeamId = value['targetTeamId']?.toString();
            break;
          }
        }
      }
    });
  }

  void _togglePlayer(String pid) {
    setState(() {
      if (_startingXi.contains(pid)) {
        if (_substitutes.length >= 18 - _requiredXiSize) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('The substitute list has reached its roster limit.')));
          return;
        }
        _startingXi.remove(pid);
        _substitutes.add(pid);
        if (_captain == pid) _captain = null;
        if (_viceCaptain == pid) _viceCaptain = null;
      } else if (_substitutes.contains(pid)) {
        _substitutes.remove(pid);
        if (_startingXi.length < _requiredXiSize) {
          _startingXi.add(pid);
        } else {
          _substitutes.add(pid);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Starting XI can have at most 11 players.')));
        }
      } else if (_eligiblePlayerIds.contains(pid)) {
        if (_startingXi.length < _requiredXiSize) {
          _startingXi.add(pid);
        } else if (_substitutes.length < 18 - _requiredXiSize) {
          _substitutes.add(pid);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A squad can have at most 18 players.')));
        }
      }
    });
  }

  Future<void> _saveLineup() async {
    if (_selectedTeam == null) return;
    setState(() => _isSaving = true);

    final chips = Map<String, dynamic>.from(_selectedTeam!.chips);
    for (final entry in chips.entries.toList()) {
      final value = entry.value;
      if (value is Map && value['gameweek']?.toString() == _activeGameweekId) {
        chips[entry.key] = {...Map<String, dynamic>.from(value), 'used': entry.key == _selectedChip};
      }
    }
    if (_selectedChip != null && _activeGameweekId != null) {
      chips[_selectedChip!] = {
        'gameweek': _activeGameweekId, 'used': true,
        if (_selectedChip == 'MMC') 'targetPlayerId': _chipTargetPlayerId,
        if (_selectedChip == 'STRADDLE') 'targetTeamId': _chipTargetTeamId,
      };
    }

    final success = await _api.saveSquadLineup(
      teamId: _selectedTeam!.id,
      startingXi: _startingXi,
      substitutes: _substitutes,
      captain: _captain,
      viceCaptain: _viceCaptain,
      chips: chips,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Lineup successfully saved to backend!' : 'Failed to save lineup.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Squad Builder'),
        actions: [
          if (!_isLoading && _selectedTeam != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveLineup,
                icon: _isSaving
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                    : const Icon(Icons.check, size: 16),
                label: const Text('SAVE'),
              ),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : Column(
              children: [
                // Team Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppTheme.surface,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<FplTeam>(
                      isExpanded: true,
                      value: _selectedTeam,
                      dropdownColor: AppTheme.cardColor,
                      items: _teams.map((t) {
                        return DropdownMenuItem<FplTeam>(
                          value: t,
                          child: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (newTeam) {
                        if (newTeam != null) _setTeam(newTeam);
                      },
                    ),
                  ),
                ),

                if (_enabledChips.isNotEmpty && _activeGameweekId != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('ACTIVE GAMEWEEK CHIP (OPTIONAL)', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                      Wrap(spacing: 6, children: [
                        ChoiceChip(label: const Text('None'), selected: _selectedChip == null, onSelected: (_) => setState(() => _selectedChip = null)),
                        ..._enabledChips.map((chip) => ChoiceChip(label: Text(chip), selected: _selectedChip == chip, onSelected: (_) => setState(() => _selectedChip = _selectedChip == chip ? null : chip))),
                      ]),
                      if (_selectedChip == 'MMC') DropdownButtonFormField<String>(
                        value: _chipTargetPlayerId,
                        decoration: const InputDecoration(labelText: 'Magic Mirror target player'),
                        items: _assignments.where((row) => row['fpl_team_id']?.toString() != _selectedTeam?.id).map((row) {
                          final id = row['player_id']?.toString() ?? '';
                          return DropdownMenuItem(value: id, child: Text(_playerMap[id]?.name ?? id));
                        }).toList(),
                        onChanged: (value) => setState(() => _chipTargetPlayerId = value),
                      ),
                      if (_selectedChip == 'STRADDLE') DropdownButtonFormField<String>(
                        value: _chipTargetTeamId,
                        decoration: const InputDecoration(labelText: 'Straddle target team'),
                        items: _teams.where((team) => team.id != _selectedTeam?.id).map((team) => DropdownMenuItem(value: team.id, child: Text(team.name))).toList(),
                        onChanged: (value) => setState(() => _chipTargetTeamId = value),
                      ),
                    ]),
                  ),
                const Divider(height: 1, color: AppTheme.border),

                // Lineup counts banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STARTING XI (${_startingXi.length}/$_requiredXiSize)',
                        style: TextStyle(
                          color: _startingXi.length == _requiredXiSize ? AppTheme.accentGreen : AppTheme.accentGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Tap arrow to swap with bench',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

                // Player List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // Starting XI Section
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text('STARTING ELEVEN', style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      ..._startingXi.map((pid) => _buildPlayerRow(pid, isStarting: true)),

                      const SizedBox(height: 16),
                      // Bench Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text('SUBSTITUTES (${_substitutes.length})', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      ..._substitutes.map((pid) => _buildPlayerRow(pid, isStarting: false)),
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Text('AVAILABLE SQUAD PLAYERS', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      ..._eligiblePlayerIds.where((pid) => !_startingXi.contains(pid) && !_substitutes.contains(pid)).map((pid) => _buildPlayerRow(pid, isStarting: false, isSubstitute: false)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerRow(String pid, {required bool isStarting, bool isSubstitute = true}) {
    final player = _playerMap[pid];
    final isCaptain = _captain == pid;
    final isViceCaptain = _viceCaptain == pid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                isStarting ? Icons.arrow_downward : (isSubstitute ? Icons.arrow_upward : Icons.add),
                color: isStarting ? AppTheme.accentRed : AppTheme.accentGreen,
                size: 20,
              ),
              onPressed: () => _togglePlayer(pid),
              tooltip: isStarting ? 'Move to bench' : (isSubstitute ? 'Move to Starting XI' : 'Add to squad'),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player?.name ?? 'Player $pid',
                    style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    '${player?.role ?? "N/A"} • ${(player?.iplTeamId ?? "").toUpperCase()} • ₹${player?.basePrice ?? 0}L',
                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (isStarting) ...[
              // Captain Toggle Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_captain == pid) {
                      _captain = null;
                    } else {
                      _captain = pid;
                      if (_viceCaptain == pid) _viceCaptain = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCaptain ? AppTheme.accentGold : AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                  child: Text(
                    'C',
                    style: TextStyle(color: isCaptain ? Colors.black : AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Vice Captain Toggle Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_viceCaptain == pid) {
                      _viceCaptain = null;
                    } else {
                      _viceCaptain = pid;
                      if (_captain == pid) _captain = null;
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isViceCaptain ? AppTheme.primaryNeon : AppTheme.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.primaryNeon),
                  ),
                  child: Text(
                    'VC',
                    style: TextStyle(color: isViceCaptain ? Colors.black : AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

