import 'package:flutter/material.dart';
import '../models/fpl_team.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/player_card.dart';
import 'squad_builder_screen.dart';

class TeamDetailScreen extends StatefulWidget {
  final FplTeam team;

  const TeamDetailScreen({super.key, required this.team});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, Player> _playerMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    final players = await _api.getPlayers();
    final map = <String, Player>{};
    for (final p in players) {
      map[p.id] = p;
    }
    if (mounted) {
      setState(() {
        _playerMap = map;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final team = widget.team;

    return Scaffold(
      appBar: AppBar(
        title: Text(team.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.primaryNeon),
            tooltip: 'Edit Squad',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SquadBuilderScreen(initialTeamId: team.id)),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryNeon,
          labelColor: AppTheme.primaryNeon,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(text: 'STARTING XI (${team.startingXi.length})'),
            Tab(text: 'BENCH (${team.substitutes.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : Column(
              children: [
                // Team Header Stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: AppTheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat('OWNER', team.owner ?? 'N/A'),
                      _stat('BUDGET', '₹${team.budget}L'),
                      _stat('FRANCHISE', (team.iplTeamId ?? 'IPL').toUpperCase()),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.border),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Starting XI List
                      _buildPlayerList(team.startingXi, isStarting: true),
                      // Bench List
                      _buildPlayerList(team.substitutes, isStarting: false),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPlayerList(List<String> playerIds, {required bool isStarting}) {
    if (playerIds.isEmpty) {
      return Center(
        child: Text(
          isStarting ? 'No players in Starting XI' : 'No substitute bench players',
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: playerIds.length,
      itemBuilder: (context, index) {
        final pid = playerIds[index];
        final player = _playerMap[pid];

        if (player == null) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text('Player $pid', style: const TextStyle(color: AppTheme.textMuted)),
            ),
          );
        }

        final isCaptain = widget.team.captain == pid;
        final isViceCaptain = widget.team.viceCaptain == pid;

        return PlayerCard(
          player: player,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCaptain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentGold),
                  ),
                  child: const Text('C', style: TextStyle(color: AppTheme.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              if (isViceCaptain)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryNeon.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryNeon),
                  ),
                  child: const Text('VC', style: TextStyle(color: AppTheme.primaryNeon, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.totalPoints}',
                    style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Text('PTS', style: TextStyle(color: AppTheme.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

