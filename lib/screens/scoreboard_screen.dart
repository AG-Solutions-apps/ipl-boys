import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fpl_team.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'team_detail_screen.dart';

class ScoreboardScreen extends StatefulWidget {
  const ScoreboardScreen({super.key});

  @override
  State<ScoreboardScreen> createState() => _ScoreboardScreenState();
}

class _ScoreboardScreenState extends State<ScoreboardScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<FplTeam> _teams = [];
  Map<String, int> _teamScores = {};

  @override
  void initState() {
    super.initState();
    _loadScoreboard();
  }

  Future<void> _loadScoreboard() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    final teams = await _api.getFplTeams(profileId: auth.activeProfileId);
    final scores = await _api.getTeamScores(profileId: auth.activeProfileId);

    // Compute total points per team
    final Map<String, int> totals = {};
    for (final s in scores) {
      final teamId = s['team_id']?.toString() ?? '';
      final pts = int.tryParse(s['points']?.toString() ?? '0') ?? 0;
      totals[teamId] = (totals[teamId] ?? 0) + pts;
    }

    // Sort teams by points descending
    teams.sort((a, b) {
      final ptsA = totals[a.id] ?? 0;
      final ptsB = totals[b.id] ?? 0;
      return ptsB.compareTo(ptsA);
    });

    if (mounted) {
      setState(() {
        _teams = teams;
        _teamScores = totals;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Scoreboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadScoreboard,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : _teams.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.leaderboard_outlined, size: 54, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        const Text(
                          'No Leaderboard Data',
                          style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Waiting for live backend tables to respond.\nIf server returns 500, verify server storage permissions & database credentials.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _loadScoreboard,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry Connection'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadScoreboard,
                  color: AppTheme.primaryNeon,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      final team = _teams[index];
                      final points = _teamScores[team.id] ?? 0;
                      final rank = index + 1;

                      Color rankColor = AppTheme.textMuted;
                      if (rank == 1) rankColor = AppTheme.accentGold;
                      if (rank == 2) rankColor = const Color(0xFFC0C0C0);
                      if (rank == 3) rankColor = const Color(0xFFCD7F32);

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: rankColor.withOpacity(0.5)),
                            ),
                            child: Center(
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: rankColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            team.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            'Owner: ${team.owner ?? "N/A"} • Budget: ₹${team.budget}L',
                            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$points',
                                style: const TextStyle(
                                  color: AppTheme.primaryNeon,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text(
                                'TOTAL PTS',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TeamDetailScreen(team: team)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
