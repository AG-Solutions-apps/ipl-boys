import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends State<RulesScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _commissionComments = [];
  List<Map<String, dynamic>> _adminBonuses = [];

  @override
  void initState() {
    super.initState();
    _loadDynamicRulesData();
  }

  Future<void> _loadDynamicRulesData() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthService>(context, listen: false);

    final comments = await _api.getCommissionComments(profileId: auth.activeProfileId);
    final bonuses = await _api.getAdminBonuses(profileId: auth.activeProfileId);

    if (mounted) {
      setState(() {
        _commissionComments = comments;
        _adminBonuses = bonuses;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rules & League Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDynamicRulesData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryNeon))
          : RefreshIndicator(
              onRefresh: _loadDynamicRulesData,
              color: AppTheme.primaryNeon,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Dynamic Commissioner Announcements if available
                  if (_commissionComments.isNotEmpty) ...[
                    _dynamicSectionHeader('COMMISSIONER ANNOUNCEMENTS', AppTheme.accentGold),
                    ..._commissionComments.map((c) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c['title']?.toString() ?? 'Official Notice',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentGold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c['comment']?.toString() ?? c['content']?.toString() ?? '',
                                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Dynamic Admin Bonuses if configured in database
                  if (_adminBonuses.isNotEmpty) ...[
                    _dynamicSectionHeader('LEAGUE SPECIAL BONUSES', AppTheme.accentPurple),
                    ..._adminBonuses.map((b) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(b['reason']?.toString() ?? 'Bonus Point Rule', style: const TextStyle(fontWeight: FontWeight.w600)),
                          trailing: Text(
                            '+${b['points'] ?? 0} pts',
                            style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Standard Fantasy Rules (Dynamic Rendering)
                  _ruleSection('BATTING POINTS', [
                    _ruleRow('Run Scored', '+1 pt'),
                    _ruleRow('Boundary (Four)', '+1 bonus pt'),
                    _ruleRow('Over Boundary (Six)', '+2 bonus pts'),
                    _ruleRow('30 Run Milestone', '+4 bonus pts'),
                    _ruleRow('Half Century (50 Runs)', '+8 bonus pts'),
                    _ruleRow('Century (100 Runs)', '+16 bonus pts'),
                    _ruleRow('Duck (Dismissed on 0)', '-2 pts'),
                  ]),
                  const SizedBox(height: 16),
                  _ruleSection('BOWLING POINTS', [
                    _ruleRow('Wicket (Excl. Run Out)', '+25 pts'),
                    _ruleRow('Maiden Over', '+8 pts'),
                    _ruleRow('3 Wicket Haul', '+4 bonus pts'),
                    _ruleRow('4 Wicket Haul', '+8 bonus pts'),
                    _ruleRow('5 Wicket Haul', '+16 bonus pts'),
                    _ruleRow('Economy < 5.0 RPO', '+6 pts'),
                    _ruleRow('Economy > 10.0 RPO', '-2 pts'),
                  ]),
                  const SizedBox(height: 16),
                  _ruleSection('FIELDING POINTS', [
                    _ruleRow('Catch', '+8 pts'),
                    _ruleRow('Stumping', '+12 pts'),
                    _ruleRow('Run Out (Direct Hit)', '+12 pts'),
                    _ruleRow('Run Out (Thrower / Catcher)', '+6 pts each'),
                    _ruleRow('3 Catches in Match', '+4 bonus pts'),
                  ]),
                  const SizedBox(height: 16),
                  _ruleSection('CAPTAINS & CHIPS', [
                    _ruleRow('Captain (C)', '2x Multiplier on Total Pts'),
                    _ruleRow('Vice-Captain (VC)', '1.5x Multiplier on Total Pts'),
                    _ruleRow('Triple Captain (TC)', '3x Multiplier on Captain'),
                    _ruleRow('H11 (Heavy 11)', 'Only top 11 scores count'),
                    _ruleRow('MMC (Money Money)', 'Bonus auction cash rewards'),
                    _ruleRow('Straddle', 'Steal opponent points bonus'),
                  ]),
                ],
              ),
            ),
    );
  }

  Widget _dynamicSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  Widget _ruleSection(String title, List<Widget> rows) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(color: AppTheme.primaryNeon, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.border, height: 1),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _ruleRow(String rule, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(rule, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
          Text(points, style: const TextStyle(color: AppTheme.accentGreen, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
