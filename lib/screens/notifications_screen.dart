import 'package:flutter/material.dart';
import '../main.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _reminderEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F5132),
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F5132),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Get a daily notification at 8:00 AM to log your sugar intake.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable daily reminder'),
              value: _reminderEnabled,
              onChanged: (val) async {
                setState(() {
                  _reminderEnabled = val;
                });
                if (val) {
                  try {
                    await scheduleDailyReminder();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Daily reminder enabled!'),
                          backgroundColor: Color(0xFF6ABF69),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not schedule reminder: $e'),
                          backgroundColor: const Color(0xFFF2A93B),
                        ),
                      );
                    }
                    setState(() {
                      _reminderEnabled = false;
                    });
                  }
                } else {
                  await flutterLocalNotificationsPlugin.cancel(0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Daily reminder disabled.'),
                        backgroundColor: Color(0xFFF2A93B),
                      ),
                    );
                  }
                }
              },
              activeThumbColor: const Color(0xFF2F5132),
            ),
          ],
        ),
      ),
    );
  }
}

