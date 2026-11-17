import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/player.dart';
import '../theme/app_theme.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final VoidCallback? onTap;
  final Widget? trailing;

  const PlayerCard({
    super.key,
    required this.player,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(AppConfig.iplColors[player.iplTeamId.toLowerCase()] ?? 0xFF3B82F6);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Player Avatar / Role Indicator
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: teamColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: teamColor.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(
                    player.role.toUpperCase(),
                    style: TextStyle(
                      color: teamColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Player Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            player.name,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (player.isOverseas) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.flight_takeoff, color: AppTheme.accentGold, size: 14),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        // Franchise Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: teamColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            player.iplTeamId.toUpperCase(),
                            style: TextStyle(
                              color: teamColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          player.tier,
                          style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₹${player.basePrice}L',
                          style: const TextStyle(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total Points or Trailing Widget
              if (trailing != null)
                trailing!
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${player.totalPoints}',
                      style: const TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'PTS',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

