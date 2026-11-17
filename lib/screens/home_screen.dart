import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'scoreboard_screen.dart';
import 'fpl_teams_screen.dart';
import 'squad_builder_screen.dart';
import 'marketplace_screen.dart';
import 'trades_screen.dart';
import 'gameweeks_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  int _teamsCount = 0;
  int _playersCount = 0;
  int _tradesCount = 0;
  bool _backendOnline = false;
  String? _lastProfileId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentPid = Provider.of<AuthService>(context).activeProfileId;
    if (_lastProfileId != null && _lastProfileId != currentPid) {
      _lastProfileId = currentPid;
      _loadDashboardData();
    } else {
      _lastProfileId = currentPid;
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    final online = await _api.testBackendConnection();
    final teams = await _api.getFplTeams(profileId: auth.activeProfileId);
    final players = await _api.getPlayers();
    final trades = await _api.getTrades(profileId: auth.activeProfileId);

    if (mounted) {
      setState(() {
        _backendOnline = online;
        _teamsCount = teams.length;
        _playersCount = players.length;
        _tradesCount = trades.length;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          // Connection Status Pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _backendOnline ? AppTheme.accentGreen.withOpacity(0.15) : AppTheme.accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _backendOnline ? AppTheme.accentGreen : AppTheme.accentRed,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _backendOnline ? AppTheme.accentGreen : AppTheme.accentRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _backendOnline ? 'LIVE API ONLINE' : 'API OFFLINE',
                  style: TextStyle(
                    color: _backendOnline ? AppTheme.accentGreen : AppTheme.accentRed,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppTheme.primaryNeon,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dynamic Welcome Banner
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ACTIVE LEAGUE PROFILE',
                                      style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      auth.activeProfileName,
                                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGold.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emoji_events, color: AppTheme.accentGold, size: 28),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Live metrics row
                          Row(
                            children: [
                              _metricBadge('TEAMS', '$_teamsCount', AppTheme.primaryNeon),
                              const SizedBox(width: 12),
                              _metricBadge('PLAYERS', '$_playersCount', AppTheme.accentGreen),
                              const SizedBox(width: 12),
                              _metricBadge('TRADES', '$_tradesCount', AppTheme.accentPurple),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'FANTASY HUB',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),

                    // Navigation Grid with Card Assets
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                      children: [
                        _navCard(
                          title: 'Scoreboard',
                          subtitle: 'Live standings & points',
                          imageAsset: 'assets/images/card-scoreboard.jpg',
                          color: AppTheme.accentGold,
                          icon: Icons.leaderboard,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScoreboardScreen())),
                        ),
                        _navCard(
                          title: 'Squad Builder',
                          subtitle: 'Pick Starting XI & C/VC',
                          imageAsset: 'assets/images/card-starting11.jpg',
                          color: AppTheme.primaryNeon,
                          icon: Icons.sports_cricket,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SquadBuilderScreen())),
                        ),
                        _navCard(
                          title: 'Marketplace',
                          subtitle: 'Auction & player pool',
                          imageAsset: 'assets/images/card-marketplace.jpg',
                          color: AppTheme.accentGreen,
                          icon: Icons.storefront,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                        ),
                        _navCard(
                          title: 'Trades Hub',
                          subtitle: 'Execute live trades',
                          imageAsset: 'assets/images/card-trades.jpg',
                          color: AppTheme.accentPurple,
                          icon: Icons.swap_horiz,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TradesScreen())),
                        ),
                        _navCard(
                          title: 'FPL Teams',
                          subtitle: 'Inspect all rosters',
                          imageAsset: 'assets/images/card-fpl-teams.jpg',
                          color: const Color(0xFF3B82F6),
                          icon: Icons.groups,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FplTeamsScreen())),
                        ),
                        _navCard(
                          title: 'Gameweeks',
                          subtitle: 'Schedule & locked status',
                          imageAsset: 'assets/images/card-fixtures.jpg',
                          color: const Color(0xFFF97316),
                          icon: Icons.calendar_today,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameweeksScreen())),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metricBadge(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _navCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image with dark gradient overlay
            Image.asset(
              imageAsset,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: AppTheme.cardColor),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Card Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
