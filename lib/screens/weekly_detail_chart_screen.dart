import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/sugar_provider.dart';

enum WeeklyChartView { entries, cumulative }

class WeeklyDetailChartScreen extends StatefulWidget {
  const WeeklyDetailChartScreen({super.key});

  @override
  State<WeeklyDetailChartScreen> createState() =>
      _WeeklyDetailChartScreenState();
}

class _WeeklyDetailChartScreenState extends State<WeeklyDetailChartScreen> {
  WeeklyChartView _view = WeeklyChartView.entries;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly details'),
        backgroundColor: const Color(0xFF2F5132),
        foregroundColor: Colors.white,
      ),
      body: Consumer<SugarProvider>(
        builder: (context, sugarProvider, child) {
          final now = DateTime.now();
          final startOfWeek = DateTime(now.year, now.month, now.day)
              .subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 7));

          final entries = sugarProvider.sugarEntries
              .map((raw) {
                final date = DateTime.parse(raw['date'] as String);
                return _WeeklyEntry(
                  date: date,
                  grams: (raw['grams'] as num).toDouble(),
                  category: raw['category'] as String?,
                );
              })
              .where((entry) =>
                  !entry.date.isBefore(startOfWeek) && entry.date.isBefore(endOfWeek))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          if (entries.isEmpty) {
            return const _EmptyState();
          }

          final spots = _buildSpots(entries, startOfWeek);
          final limit = sugarProvider.dailySugarLimit;
          final chartMaxY = _resolveChartMax(limit, spots);

          final daySummaries = _buildDaySummaries(entries, startOfWeek);

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tap or drag across the chart to inspect exact entries.',
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      _ChartModeSelector(
                        active: _view,
                        onChanged: (mode) {
                          setState(() => _view = mode);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 320,
                        child: _WeeklyLineChart(
                          view: _view,
                          limit: limit,
                          maxY: chartMaxY,
                          startOfWeek: startOfWeek,
                          spots: spots,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '${entries.length} entr${entries.length == 1 ? 'y' : 'ies'} logged this week',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2F5132),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final itemIndex = index ~/ 2;
                    if (index.isOdd) {
                      return const SizedBox(height: 12);
                    }
                    if (itemIndex >= daySummaries.length) {
                      return null;
                    }
                    final summary = daySummaries[itemIndex];
                    return _DailySummaryCard(summary: summary);
                  },
                  childCount: daySummaries.isEmpty
                      ? 0
                      : daySummaries.length * 2 - 1,
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          );
        },
      ),
    );
  }

  List<FlSpot> _buildSpots(List<_WeeklyEntry> entries, DateTime startOfWeek) {
    if (_view == WeeklyChartView.cumulative) {
      double running = 0;
      return entries.map((entry) {
        running += entry.grams;
        return FlSpot(_hoursSince(startOfWeek, entry.date), running);
      }).toList();
    }

    return entries
        .map(
          (entry) => FlSpot(
            _hoursSince(startOfWeek, entry.date),
            entry.grams,
          ),
        )
        .toList();
  }

  double _resolveChartMax(double limit, List<FlSpot> spots) {
    if (spots.isEmpty) return limit == 0 ? 10 : limit * 1.2;
    final maxSpot = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
    final baseline = _view == WeeklyChartView.entries ? limit : maxSpot;
    final target = maxSpot > baseline ? maxSpot : baseline;
    if (target == 0) return 10;
    return target + target * 0.2;
  }

  List<_DaySummary> _buildDaySummaries(
    List<_WeeklyEntry> entries,
    DateTime startOfWeek,
  ) {
    final summaries = <_DaySummary>[];
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final dayKey = DateTime(day.year, day.month, day.day);
      final dayEntries = entries
          .where((entry) => _sameDay(entry.date, dayKey))
          .toList();
      if (dayEntries.isEmpty) continue;
      final total = dayEntries.fold<double>(0, (sum, entry) => sum + entry.grams);
      summaries.add(_DaySummary(day: day, entries: dayEntries, totalGrams: total));
    }
    return summaries;
  }

  double _hoursSince(DateTime reference, DateTime point) {
    return point.difference(reference).inMinutes / 60.0;
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeeklyLineChart extends StatelessWidget {
  const _WeeklyLineChart({
    required this.view,
    required this.limit,
    required this.maxY,
    required this.startOfWeek,
    required this.spots,
  });

  final WeeklyChartView view;
  final double limit;
  final double maxY;
  final DateTime startOfWeek;
  final List<FlSpot> spots;

  static const _entryColor = Color(0xFF6ABF69);
  static const _cumulativeColor = Color(0xFF2F5132);
  static const _limitColor = Color(0xFFF2A93B);

  @override
  Widget build(BuildContext context) {
    final color = view == WeeklyChartView.entries ? _entryColor : _cumulativeColor;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 24.0 * 7,
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touched) {
                final timestamp = startOfWeek.add(
                  Duration(minutes: (touched.x * 60).round()),
                );
                final timeLabel = DateFormat('EEE, MMM d • h:mma').format(timestamp);
                final valueLabel = view == WeeklyChartView.entries
                    ? '${touched.y.toStringAsFixed(1)} g'
                    : '${touched.y.toStringAsFixed(1)} g total';
                return LineTooltipItem(
                  '$timeLabel\n$valueLabel',
                  const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          horizontalInterval: maxY <= 40 ? 10 : maxY / 4,
          verticalInterval: 24,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.15),
            dashArray: const [5, 5],
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.withOpacity(0.12),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 24,
              getTitlesWidget: (value, meta) {
                final labelDate = startOfWeek.add(Duration(hours: value.toInt()));
                return Transform.translate(
                  offset: const Offset(0, 8),
                  child: Text(
                    DateFormat('E\nha').format(labelDate),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        extraLinesData: view == WeeklyChartView.entries
            ? ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: limit,
                    dashArray: const [4, 4],
                    color: _limitColor,
                    strokeWidth: 2,
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      labelResolver: (_) => 'Daily limit (${limit.toStringAsFixed(0)}g)',
                      style: const TextStyle(
                        color: _limitColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            : ExtraLinesData(horizontalLines: const []),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 3,
            color: color,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.15),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final exceedsLimit = view == WeeklyChartView.entries && spot.y > limit;
                return FlDotCirclePainter(
                  radius: 5,
                  color: exceedsLimit ? _limitColor : color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartModeSelector extends StatelessWidget {
  const _ChartModeSelector({required this.active, required this.onChanged});

  final WeeklyChartView active;
  final ValueChanged<WeeklyChartView> onChanged;

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      borderRadius: BorderRadius.circular(24),
      constraints: const BoxConstraints(minHeight: 40, minWidth: 120),
      isSelected: WeeklyChartView.values
          .map((mode) => mode == active)
          .toList(),
      onPressed: (index) => onChanged(WeeklyChartView.values[index]),
      selectedColor: Colors.white,
      color: const Color(0xFF2F5132),
      fillColor: const Color(0xFF2F5132),
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Each entry'),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('Cumulative'),
        ),
      ],
    );
  }
}

class _DailySummaryCard extends StatelessWidget {
  const _DailySummaryCard({required this.summary});

  final _DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, MMM d').format(summary.day);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2F5132),
                  ),
                ),
                Text(
                  '${summary.totalGrams.toStringAsFixed(1)} g',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF2A93B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final entry in summary.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6ABF69).withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        DateFormat('h:mma').format(entry.date),
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                    Text(
                      '${entry.grams.toStringAsFixed(1)} g',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (entry.category?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F6E9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            entry.category!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2F5132),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bar_chart, size: 64, color: Color(0xFF6ABF69)),
            SizedBox(height: 16),
            Text(
              'No sugar logs yet this week',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Log a sugar entry to see your detailed weekly trend here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyEntry {
  const _WeeklyEntry({
    required this.date,
    required this.grams,
    this.category,
  });

  final DateTime date;
  final double grams;
  final String? category;
}

class _DaySummary {
  const _DaySummary({
    required this.day,
    required this.entries,
    required this.totalGrams,
  });

  final DateTime day;
  final List<_WeeklyEntry> entries;
  final double totalGrams;
}
