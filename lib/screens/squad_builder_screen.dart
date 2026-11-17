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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    final teams = await _api.getFplTeams(profileId: auth.activeProfileId);
    final players = await _api.getPlayers();
    final pMap = {for (var p in players) p.id: p};

    FplTeam? initialTeam;
    if (widget.initialTeamId != null) {
      initialTeam = teams.firstWhere((t) => t.id == widget.initialTeamId, orElse: () => teams.first);
    } else if (teams.isNotEmpty) {
      initialTeam = teams.first;
    }

    if (mounted) {
      setState(() {
        _teams = teams;
        _playerMap = pMap;
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
      _captain = team.captain;
      _viceCaptain = team.viceCaptain;
    });
  }

  void _togglePlayer(String pid) {
    setState(() {
      if (_startingXi.contains(pid)) {
        _startingXi.remove(pid);
        _substitutes.add(pid);
        if (_captain == pid) _captain = null;
        if (_viceCaptain == pid) _viceCaptain = null;
      } else if (_substitutes.contains(pid)) {
        if (_startingXi.length >= 11) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Starting XI can have at most 11 players!')),
          );
          return;
        }
        _substitutes.remove(pid);
        _startingXi.add(pid);
      }
    });
  }

  Future<void> _saveLineup() async {
    if (_selectedTeam == null) return;
    setState(() => _isSaving = true);

    final success = await _api.saveSquadLineup(
      teamId: _selectedTeam!.id,
      startingXi: _startingXi,
      substitutes: _substitutes,
      captain: _captain,
      viceCaptain: _viceCaptain,
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
                const Divider(height: 1, color: AppTheme.border),

                // Lineup counts banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: AppTheme.cardColor,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'STARTING XI (${_startingXi.length}/11)',
                        style: TextStyle(
                          color: _startingXi.length == 11 ? AppTheme.accentGreen : AppTheme.accentGold,
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
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlayerRow(String pid, {required bool isStarting}) {
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
                isStarting ? Icons.arrow_downward : Icons.arrow_upward,
                color: isStarting ? AppTheme.accentRed : AppTheme.accentGreen,
                size: 20,
              ),
              onPressed: () => _togglePlayer(pid),
              tooltip: isStarting ? 'Move to bench' : 'Move to Starting XI',
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

