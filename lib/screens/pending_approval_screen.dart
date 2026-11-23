import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_top, size: 42, color: AppTheme.accentGold),
              const SizedBox(height: 18),
              const Text('Account awaiting approval', style: TextStyle(color: AppTheme.textPrimary, fontSize: 21, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('An administrator must approve your account before you can enter a league.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 22),
              ElevatedButton(onPressed: () => context.read<AuthService>().logout(), child: const Text('SIGN OUT')),
            ],
          ),
        ),
      ),
    );
  }
}
