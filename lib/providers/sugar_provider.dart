import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SugarProvider with ChangeNotifier {
  List<Map<String, dynamic>> _sugarEntries = [];
  int _currentStreak = 0;
  int _longestStreak = 0;
  double _dailySugarLimit = 25.0; // grams

  List<Map<String, dynamic>> get sugarEntries => _sugarEntries;
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  double get dailySugarLimit => _dailySugarLimit;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;
  CollectionReference<Map<String, dynamic>> get _userCol =>
      FirebaseFirestore.instance.collection('users');

  Future<void> loadData() async {
    if (_uid == null) return;
    final userDoc = await _userCol.doc(_uid).get();
    final data = userDoc.data();
    _sugarEntries = List<Map<String, dynamic>>.from(
      data?['sugar_entries'] ?? [],
    );
    _dailySugarLimit = (data?['daily_sugar_limit'] ?? 25.0).toDouble();
    // Recompute streaks locally to ensure correctness
    _recalculateStreaksFromHistory();
    notifyListeners();
  }

  Future<void> addSugarEntry(double grams, String category) async {
    if (_uid == null) return;
    final entry = {
      'date': DateTime.now().toIso8601String(),
      'grams': grams,
      'category': category,
    };
    // Optimistically update local state so UI reflects changes immediately
    _sugarEntries.add(entry);
    _recalculateStreaksFromHistory();
    notifyListeners();
    await _saveData();
  }

  Future<void> deleteSugarEntry(int index) async {
    if (_uid == null) return;
    _sugarEntries.removeAt(index);
    _recalculateStreaksFromHistory();
    notifyListeners();
    await _saveData();
  }

  Future<void> updateDailySugarLimit(double limit) async {
    if (_uid == null) return;
    _dailySugarLimit = limit;
    _recalculateStreaksFromHistory();
    notifyListeners();
    await _saveData();
  }

  Future<void> _saveData() async {
    if (_uid == null) return;
    await _userCol.doc(_uid).set({
      'sugar_entries': _sugarEntries,
      'current_streak': _currentStreak,
      'longest_streak': _longestStreak,
      'daily_sugar_limit': _dailySugarLimit,
    });
  }

  void _recalculateStreaksFromHistory() {
    // Aggregate grams per calendar day
    final Map<DateTime, double> totalsByDay = {};
    for (final entry in _sugarEntries) {
      final date = DateTime.parse(entry['date']);
      final dayKey = DateTime(date.year, date.month, date.day);
      totalsByDay[dayKey] = (totalsByDay[dayKey] ?? 0.0) + (entry['grams'] as num).toDouble();
    }

    // Determine longest streak across all days and current streak up to today
    int computedLongest = 0;
    int computedCurrent = 0;

    // Sort all unique days ascending
    final days = totalsByDay.keys.toList()..sort();

    // Helper to check if a day is on-limit (<= daily limit)
    bool isOnLimit(DateTime day) {
      final total = totalsByDay[day] ?? 0.0;
      return total <= _dailySugarLimit;
    }

    // Compute longest streak over all days with entries, requiring consecutive calendar days
    int run = 0;
    DateTime? previousDay;
    for (final day in days) {
      final bool onLimit = isOnLimit(day);
      final bool isConsecutive = previousDay != null &&
          day.difference(previousDay).inDays == 1;
      if (onLimit) {
        if (previousDay != null && isConsecutive) {
          run += 1;
        } else {
          run = 1;
        }
        if (run > computedLongest) computedLongest = run;
      } else {
        run = 0;
      }
      previousDay = day;
    }

    // Compute current streak counting backwards from today where the day has entries and is on-limit
    DateTime cursor = DateTime.now();
    while (true) {
      final dayKey = DateTime(cursor.year, cursor.month, cursor.day);
      if (totalsByDay.containsKey(dayKey) && isOnLimit(dayKey)) {
        computedCurrent += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        if (computedCurrent > 3650) break;
      } else {
        break;
      }
    }

    _currentStreak = computedCurrent;
    _longestStreak = computedLongest < computedCurrent ? computedCurrent : computedLongest;
  }

  double getTodaySugar() {
    final today = DateTime.now();
    return _sugarEntries
        .where((entry) {
          final entryDate = DateTime.parse(entry['date']);
          return entryDate.day == today.day &&
              entryDate.month == today.month &&
              entryDate.year == today.year;
        })
        .fold(0.0, (sum, entry) => sum + entry['grams']);
  }

  Map<String, double> getWeeklySugar() {
    final now = DateTime.now();
    final week = <String, double>{};
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      week[dayName] = _sugarEntries
          .where((entry) {
            final entryDate = DateTime.parse(entry['date']);
            return entryDate.day == date.day &&
                entryDate.month == date.month &&
                entryDate.year == date.year;
          })
          .fold(0.0, (sum, entry) => sum + entry['grams']);
    }
    return week;
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  void clear() {
    _sugarEntries = [];
    _currentStreak = 0;
    _longestStreak = 0;
    _dailySugarLimit = 25.0;
    notifyListeners();
  }
}
