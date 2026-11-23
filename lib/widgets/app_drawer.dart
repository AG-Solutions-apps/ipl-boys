import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/scoreboard_screen.dart';
import '../screens/fpl_teams_screen.dart';
import '../screens/squad_builder_screen.dart';
import '../screens/marketplace_screen.dart';
import '../screens/trades_screen.dart';
import '../screens/gameweeks_screen.dart';
import '../screens/rules_screen.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final profiles = auth.availableProfiles;
    final isLoggedIn = auth.isLoggedIn;
    final displayName = auth.currentUser?['user_metadata']?['display_name'] ?? auth.currentUser?['display_name'] ?? 'User';
    final userEmail = auth.currentUser?['email'] ?? 'Guest Mode';

    return Drawer(
      backgroundColor: AppTheme.surface,
      child: Column(
        children: [
          // Header with User Info & Dynamic League Profile Switcher
          Container(
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              color: AppTheme.cardColor,
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryNeon.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_cricket, color: AppTheme.primaryNeon, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? displayName : AppConfig.appName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 12,
                              color: isLoggedIn ? AppTheme.accentGreen : AppTheme.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Dynamic League Selector Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: profiles.isEmpty
                      ? InkWell(
                          onTap: () => auth.fetchLiveProfiles(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.shield, color: AppTheme.accentGold, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.activeProfileName,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Icon(Icons.refresh, size: 16, color: AppTheme.textMuted),
                              ],
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: profiles.containsKey(auth.activeProfileId) ? auth.activeProfileId : profiles.keys.first,
                            dropdownColor: AppTheme.cardColor,
                            icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryNeon),
                            items: profiles.entries.map((e) {
                              return DropdownMenuItem<String>(
                                value: e.key,
                                child: Row(
                                  children: [
                                    const Icon(Icons.shield, color: AppTheme.accentGold, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                auth.switchProfile(val);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),

          // Dynamic Navigation List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _navItem(
                  context,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  destination: const HomeScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.leaderboard_outlined,
                  title: 'Scoreboard',
                  destination: const ScoreboardScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.groups_outlined,
                  title: 'FPL Teams',
                  destination: const FplTeamsScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.sports_cricket_outlined,
                  title: 'Squad Builder',
                  destination: const SquadBuilderScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.storefront_outlined,
                  title: 'Marketplace',
                  destination: const MarketplaceScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.swap_horiz_outlined,
                  title: 'Trades',
                  destination: const TradesScreen(),
                ),
                _navItem(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Gameweeks',
                  destination: const GameweeksScreen(),
                ),
                const Divider(color: AppTheme.border, height: 24),
                _navItem(
                  context,
                  icon: Icons.gavel_outlined,
                  title: 'Rules & Scoring',
                  destination: const RulesScreen(),
                ),
                const Divider(color: AppTheme.border, height: 24),

                // Sign In / Sign Out Tile
                if (!isLoggedIn)
                  ListTile(
                    leading: const Icon(Icons.login, color: AppTheme.primaryNeon, size: 22),
                    title: const Text(
                      'Sign In / Register',
                      style: TextStyle(color: AppTheme.primaryNeon, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.accentRed, size: 22),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppTheme.accentRed, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await auth.logout();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
              ],
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'v${AppConfig.appVersion} (Live)',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                Text(
                  auth.activeProfileName,
                  style: const TextStyle(fontSize: 11, color: AppTheme.primaryNeon, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget destination,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary, size: 22),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      },
    );
  }
}
