import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/trade.dart';
import '../models/fpl_team.dart';
import '../models/player.dart';
import '../models/gameweek.dart';
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
  List<Map<String, dynamic>> _playerAssignments = [];
  List<Gameweek> _gameweeks = [];
  String? _myTeamId;

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
    final myTeams = await _api.queryTable('user_team_assignments', filters: {
      'user_id': auth.currentUser?['id']?.toString() ?? '',
      'profile_id': auth.activeProfileId,
    });
    final assignments = await _api.queryTable('player_assignments', filters: {'profile_id': auth.activeProfileId});
    final gameweeks = await _api.getGameweeks();

    if (mounted) {
      setState(() {
        _trades = trades;
        _teamMap = {for (var t in teams) t.id: t};
        _playerMap = {for (var p in players) p.id: p};
        _myTeamId = myTeams.isNotEmpty ? myTeams.first['team_id']?.toString() : null;
        _playerAssignments = assignments.cast<Map<String, dynamic>>();
        _gameweeks = gameweeks;
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

  Future<void> _createTrade() async {
    final myTeamId = _myTeamId;
    if (myTeamId == null) return;
    String? targetTeamId;
    String? offeredPlayerId;
    String? requestedPlayerId;
    String? loanStartId;
    String? loanEndId;
    String moneyFrom = '0';
    String moneyTo = '0';
    bool permanent = true;
    final teams = _teamMap.values.where((team) => team.id != myTeamId).toList();
    if (teams.isEmpty) return;
    targetTeamId = teams.first.id;
    final picked = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setDialogState) {
        final fromPlayers = _playerAssignments.where((row) => row['fpl_team_id']?.toString() == myTeamId).toList();
        final toPlayers = _playerAssignments.where((row) => row['fpl_team_id']?.toString() == targetTeamId).toList();
        Widget playerPicker(String label, List<Map<String, dynamic>> rows, String? value, ValueChanged<String?> onChanged) =>
            DropdownButtonFormField<String>(
              value: rows.any((row) => row['player_id']?.toString() == value) ? value : null,
              decoration: InputDecoration(labelText: label),
              items: [const DropdownMenuItem<String>(value: null, child: Text('No player')), ...rows.map((row) {
                final id = row['player_id']?.toString() ?? '';
                return DropdownMenuItem(value: id, child: Text(_playerMap[id]?.name ?? id));
              })], onChanged: onChanged,
            );
        return AlertDialog(
          title: const Text('Propose a trade'),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(value: targetTeamId, decoration: const InputDecoration(labelText: 'Trade with'),
              items: teams.map((team) => DropdownMenuItem(value: team.id, child: Text(team.name))).toList(),
              onChanged: (value) => setDialogState(() { targetTeamId = value; requestedPlayerId = null; })),
            const SizedBox(height: 8), playerPicker('Player you offer', fromPlayers, offeredPlayerId, (v) => setDialogState(() => offeredPlayerId = v)),
            const SizedBox(height: 8), playerPicker('Player you request', toPlayers, requestedPlayerId, (v) => setDialogState(() => requestedPlayerId = v)),
            TextFormField(decoration: const InputDecoration(labelText: 'Cash you offer'), keyboardType: TextInputType.number, onChanged: (v) => moneyFrom = v),
            TextFormField(decoration: const InputDecoration(labelText: 'Cash you request'), keyboardType: TextInputType.number, onChanged: (v) => moneyTo = v),
            SwitchListTile(title: const Text('Permanent transfer'), value: permanent, onChanged: (v) => setDialogState(() => permanent = v)),
            if (!permanent) ...[
              DropdownButtonFormField<String>(value: loanStartId, decoration: const InputDecoration(labelText: 'Loan starts'),
                items: _gameweeks.map((week) => DropdownMenuItem(value: week.id, child: Text(week.name))).toList(),
                onChanged: (v) => setDialogState(() => loanStartId = v)),
              DropdownButtonFormField<String>(value: loanEndId, decoration: const InputDecoration(labelText: 'Loan ends'),
                items: _gameweeks.map((week) => DropdownMenuItem(value: week.id, child: Text(week.name))).toList(),
                onChanged: (v) => setDialogState(() => loanEndId = v)),
            ],
          ])),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, {
              'target': targetTeamId, 'offered': offeredPlayerId, 'requested': requestedPlayerId,
              'moneyFrom': moneyFrom, 'moneyTo': moneyTo, 'permanent': permanent,
              'start': loanStartId, 'end': loanEndId,
            }), child: const Text('Send proposal'))],
        );
      }),
    );
    if (picked == null || !mounted) return;
    final success = await _api.createTrade(
      profileId: Provider.of<AuthService>(context, listen: false).activeProfileId,
      fromTeamId: myTeamId,
      toTeamId: picked['target'] as String,
      playersFrom: picked['offered'] == null ? [] : [picked['offered'] as String],
      playersTo: picked['requested'] == null ? [] : [picked['requested'] as String],
      moneyFrom: int.tryParse(picked['moneyFrom'] as String) ?? 0,
      moneyTo: int.tryParse(picked['moneyTo'] as String) ?? 0,
      isPermanent: picked['permanent'] as bool,
      loanStartGameweek: picked['start'] as String?,
      loanEndGameweek: picked['end'] as String?,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? 'Trade proposal sent.' : 'Could not send the trade proposal. Check the teams, budget, and player ownership.')));
    if (success) _loadTrades();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trades Hub'),
        actions: [
          if (_myTeamId != null) IconButton(tooltip: 'Propose trade', icon: const Icon(Icons.add), onPressed: _createTrade),
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
                                  onPressed: _myTeamId == trade.toTeamId ? () => _executeTrade(trade.id) : null,
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

