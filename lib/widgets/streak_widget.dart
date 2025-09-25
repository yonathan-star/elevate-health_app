import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sugar_provider.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SugarProvider>(
      builder: (context, sugarProvider, child) {
        final streak = sugarProvider.currentStreak;
        final badges = <Widget>[];
        if (streak >= 3) {
          badges.add(_buildBadge('3 Days', Icons.eco, const Color(0xFF6ABF69)));
        }
        if (streak >= 7) {
          badges.add(_buildBadge('7 Days', Icons.spa, const Color(0xFF2F5132)));
        }
        if (streak >= 14) {
          badges.add(
            _buildBadge('14 Days', Icons.emoji_events, const Color(0xFFF2A93B)),
          );
        }
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Current Streak',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2F5132),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6ABF69),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$streak days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: badges,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Longest Streak',
                    '${sugarProvider.longestStreak} days',
                    Icons.emoji_events,
                    const Color(0xFFF2A93B),
                  ),
                  _buildStatItem(
                    'Today\'s Sugar',
                    '${sugarProvider.getTodaySugar().toStringAsFixed(1)}g',
                    Icons.local_drink,
                    sugarProvider.getTodaySugar() >
                            sugarProvider.dailySugarLimit
                        ? const Color(0xFFF2A93B)
                        : const Color(0xFF6ABF69),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
