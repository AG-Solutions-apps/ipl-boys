import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final ApiService _api = ApiService();
  bool _isTesting = false;
  String? _testResult;

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    final stopwatch = Stopwatch()..start();
    final success = await _api.testBackendConnection();
    stopwatch.stop();

    setState(() {
      _isTesting = false;
      _testResult = success
          ? 'Live Backend Online! Latency: ${stopwatch.elapsedMilliseconds}ms'
          : 'Could not connect to ${AppConfig.cleanBaseUrl}. Check server or CORS configuration.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final profiles = auth.availableProfiles;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Commissioner Admin'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Server Status Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LIVE BACKEND REST API STATUS',
                    style: TextStyle(color: AppTheme.primaryNeon, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppConfig.cleanBaseUrl,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _testConnection,
                      icon: _isTesting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.speed),
                      label: const Text('TEST LIVE CONNECTION'),
                    ),
                  ),
                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _testResult!,
                      style: TextStyle(
                        color: _testResult!.startsWith('Live Backend Online') ? AppTheme.accentGreen : AppTheme.accentRed,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dynamic Active League Switcher
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DYNAMIC LEAGUE PROFILES',
                        style: TextStyle(color: AppTheme.accentGold, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, size: 18, color: AppTheme.primaryNeon),
                        tooltip: 'Sync profiles from backend',
                        onPressed: () => auth.fetchLiveProfiles(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (profiles.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Active: ${auth.activeProfileName} (${auth.activeProfileId})\nTap refresh above to sync all live profiles from database.',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    )
                  else
                    ...profiles.entries.map((e) {
                      final isSelected = auth.activeProfileId == e.key;
                      return RadioListTile<String>(
                        value: e.key,
                        groupValue: auth.activeProfileId,
                        title: Text(e.value, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        subtitle: Text(e.key, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                        activeColor: AppTheme.primaryNeon,
                        onChanged: (val) {
                          if (val != null) auth.switchProfile(val);
                        },
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Live Configuration Summary
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'LIVE API ENDPOINT CONFIG',
                    style: TextStyle(color: AppTheme.accentPurple, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your Flutter app communicates directly with your live hosted Laravel backend.\n\n'
                    'To update the endpoint at any time, change the baseUrl in:\n'
                    'frontend/lib/config/app_config.dart\n\n'
                    'All tables, teams, trades, squad builder, and scoreboards dynamically query your hosted MySQL tables in real-time.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
