import 'package:flutter/material.dart';
import '../models/gameweek.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class GameweeksScreen extends StatefulWidget {
  const GameweeksScreen({super.key});

  @override
  State<GameweeksScreen> createState() => _GameweeksScreenState();
}

class _GameweeksScreenState extends State<GameweeksScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Gameweek> _gameweeks = [];

  @override
  void initState() {
    super.initState();
    _loadGameweeks();
  }

  Future<void> _loadGameweeks() async {
    setState(() => _isLoading = true);
    final list = await _api.getGameweeks();
    if (mounted) {
      setState(() {
        _gameweeks = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gameweeks & Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGameweeks,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : _gameweeks.isEmpty
              ? const Center(child: Text('No gameweeks found.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _gameweeks.length,
                  itemBuilder: (context, index) {
                    final gw = _gameweeks[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: gw.isActive ? AppTheme.accentGreen.withOpacity(0.15) : AppTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: gw.isActive ? AppTheme.accentGreen : AppTheme.border),
                          ),
                          child: Center(
                            child: Icon(
                              gw.isLocked ? Icons.lock : Icons.lock_open,
                              color: gw.isLocked ? AppTheme.accentGold : AppTheme.accentGreen,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              gw.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (gw.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${gw.gameCount} Matches • ${gw.isLocked ? "Locked" : "Open for lineups"}',
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                        ),
                        trailing: Icon(
                          gw.isComplete ? Icons.check_circle : Icons.schedule,
                          color: gw.isComplete ? AppTheme.accentGreen : AppTheme.textMuted,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

