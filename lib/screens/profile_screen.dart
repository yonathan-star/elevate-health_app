import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sugar_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F5132),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<SugarProvider>(
        builder: (context, sugarProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.email, color: Color(0xFF6ABF69)),
                      const SizedBox(width: 8),
                      Text(
                        user.email ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2F5132),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        Provider.of<SugarProvider>(
                          context,
                          listen: false,
                        ).clear();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2A93B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Your Progress',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F5132),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatCard(
                  'Current Streak',
                  '${sugarProvider.currentStreak} days',
                  Icons.local_fire_department,
                  const Color(0xFF6ABF69),
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Longest Streak',
                  '${sugarProvider.longestStreak} days',
                  Icons.emoji_events,
                  const Color(0xFFF2A93B),
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Today\'s Sugar',
                  '${sugarProvider.getTodaySugar().toStringAsFixed(1)}g',
                  Icons.local_drink,
                  sugarProvider.getTodaySugar() > sugarProvider.dailySugarLimit
                      ? const Color(0xFFF2A93B)
                      : const Color(0xFF6ABF69),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F5132),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.settings,
                      color: Color(0xFF6ABF69),
                    ),
                    title: const Text('Daily Sugar Limit'),
                    subtitle: Text('${sugarProvider.dailySugarLimit}g'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.notifications,
                      color: Color(0xFF6ABF69),
                    ),
                    title: const Text('Notifications'),
                    subtitle: const Text('Daily reminders'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
