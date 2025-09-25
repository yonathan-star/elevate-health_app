import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sugar_provider.dart';
import '../widgets/sugar_input_card.dart';

class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F5132),
        title: const Text(
          'Daily Log',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track Your Sugar Intake',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F5132),
              ),
            ),
            const SizedBox(height: 20),
            const SugarInputCard(),
            const SizedBox(height: 20),
            const Text(
              'Today\'s Entries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F5132),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<SugarProvider>(
              builder: (context, sugarProvider, child) {
                final today = DateTime.now();
                final todayEntries = sugarProvider.sugarEntries.where((entry) {
                  final entryDate = DateTime.parse(entry['date']);
                  return entryDate.day == today.day &&
                      entryDate.month == today.month &&
                      entryDate.year == today.year;
                }).toList();

                if (todayEntries.isEmpty) {
                  return const Center(
                    child: Text(
                      'No entries for today yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: todayEntries.length,
                  itemBuilder: (context, index) {
                    final entry = todayEntries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(
                          Icons.local_drink,
                          color: Color(0xFF6ABF69),
                        ),
                        title: Text(
                          '${entry['grams']}g of ${entry['category']}',
                        ),
                        subtitle: Text(
                          _formatTime(DateTime.parse(entry['date'])),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final provider = Provider.of<SugarProvider>(
                              context,
                              listen: false,
                            );
                            final mainIndex = provider.sugarEntries.indexOf(
                              entry,
                            );
                            if (mainIndex != -1) {
                              await provider.deleteSugarEntry(mainIndex);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
