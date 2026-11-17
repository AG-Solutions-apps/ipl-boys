import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/player_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Player> _allPlayers = [];
  List<Player> _filteredPlayers = [];

  String _searchQuery = '';
  String _selectedRole = 'ALL';
  String _selectedTier = 'ALL';

  List<String> _roles = ['ALL'];
  List<String> _tiers = ['ALL'];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    setState(() => _isLoading = true);
    final players = await _api.getPlayers();
    if (mounted) {
      // Dynamically extract distinct roles and tiers from live backend players
      final dynamicRoles = players
          .map((p) => p.role.trim().toUpperCase())
          .where((r) => r.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      final dynamicTiers = players
          .map((p) => p.tier.trim())
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _allPlayers = players;
        _roles = ['ALL', ...dynamicRoles];
        _tiers = ['ALL', ...dynamicTiers];
        _applyFilters();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Player> list = List.from(_allPlayers);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) => p.name.toLowerCase().contains(q) || p.iplTeamId.toLowerCase().contains(q)).toList();
    }

    if (_selectedRole != 'ALL') {
      list = list.where((p) => p.role.trim().toUpperCase() == _selectedRole).toList();
    }

    if (_selectedTier != 'ALL') {
      list = list.where((p) => p.tier.trim() == _selectedTier).toList();
    }

    setState(() {
      _filteredPlayers = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace & Auction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayers,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Dynamic Search & Filter Header
          Container(
            padding: const EdgeInsets.all(12),
            color: AppTheme.surface,
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search player or team...',
                    prefixIcon: Icon(Icons.search, color: AppTheme.textMuted),
                  ),
                  onChanged: (val) {
                    _searchQuery = val;
                    _applyFilters();
                  },
                ),
                const SizedBox(height: 8),
                // Dynamic Role Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _roles.map((r) {
                      final isSelected = _selectedRole == r;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(r),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryNeon,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.black : AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedRole = r);
                            _applyFilters();
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 6),
                // Dynamic Tier Filter Chips
                if (_tiers.length > 1)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _tiers.map((t) {
                        final isSelected = _selectedTier == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(t),
                            selected: isSelected,
                            selectedColor: AppTheme.accentPurple,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedTier = t);
                              _applyFilters();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Player Count Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.cardColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PLAYERS (${_filteredPlayers.length} / ${_allPlayers.length})',
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Sorted by Total Pts',
                  style: TextStyle(color: AppTheme.accentGreen, fontSize: 11),
                ),
              ],
            ),
          ),

          // Player List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
                : _filteredPlayers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.person_off, size: 48, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text('No players matched your criteria.', style: TextStyle(color: AppTheme.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadPlayers,
                              child: const Text('Refresh from Live API'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPlayers,
                        color: AppTheme.primaryNeon,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _filteredPlayers.length,
                          itemBuilder: (context, index) {
                            return PlayerCard(player: _filteredPlayers[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
