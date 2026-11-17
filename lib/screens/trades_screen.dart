import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trade.dart';
import '../models/fpl_team.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Trade> _trades = [];
  Map<String, FplTeam> _teamMap = {};
  Map<String, Player> _playerMap = {};

  @override
  void initState() {
    super.initState();
    _loadTrades();
  }

  Future<void> _loadTrades() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    final trades = await _api.getTrades(profileId: auth.activeProfileId);
    final teams = await _api.getFplTeams(profileId: auth.activeProfileId);
    final players = await _api.getPlayers();

    if (mounted) {
      setState(() {
        _trades = trades;
        _teamMap = {for (var t in teams) t.id: t};
        _playerMap = {for (var p in players) p.id: p};
        _isLoading = false;
      });
    }
  }

  Future<void> _executeTrade(String tradeId) async {
    final success = await _api.executeTrade(tradeId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Trade successfully executed!' : 'Failed to execute trade.'),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      if (success) _loadTrades();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTrades,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : _trades.isEmpty
              ? const Center(child: Text('No trades found in this league.'))
              : RefreshIndicator(
                  onRefresh: _loadTrades,
                  color: AppTheme.primaryNeon,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _trades.length,
                    itemBuilder: (context, index) {
                      final trade = _trades[index];
                      final fromTeam = _teamMap[trade.fromTeamId]?.name ?? 'Team A';
                      final toTeam = _teamMap[trade.toTeamId]?.name ?? 'Team B';

                      Color statusColor = AppTheme.textMuted;
                      if (trade.status == 'accepted' || trade.status == 'completed') statusColor = AppTheme.accentGreen;
                      if (trade.status == 'pending') statusColor = AppTheme.accentGold;
                      if (trade.status == 'rejected' || trade.status == 'cancelled') statusColor = AppTheme.accentRed;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Status & Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      trade.status.toUpperCase(),
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Text(
                                    trade.isPermanent ? 'PERMANENT TRADE' : 'LOAN',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Teams Exchange
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(fromTeam, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(height: 4),
                                        ...trade.playersFrom.map((pid) => Text('• ${_playerMap[pid]?.name ?? pid}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
                                        if (trade.moneyFrom > 0)
                                          Text('+ ₹${trade.moneyFrom}L Cash', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.swap_horiz, color: AppTheme.primaryNeon, size: 24),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(toTeam, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.right),
                                        const SizedBox(height: 4),
                                        ...trade.playersTo.map((pid) => Text('• ${_playerMap[pid]?.name ?? pid}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12), textAlign: TextAlign.right)),
                                        if (trade.moneyTo > 0)
                                          Text('+ ₹${trade.moneyTo}L Cash', style: const TextStyle(color: AppTheme.accentGreen, fontSize: 12), textAlign: TextAlign.right),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              if (trade.status == 'pending') ...[
                                const SizedBox(height: 12),
                                const Divider(color: AppTheme.border, height: 1),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _executeTrade(trade.id),
                                    child: const Text('EXECUTE TRADE'),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

