import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/sugar_provider.dart';

class WeeklyDetailChartScreen extends StatelessWidget {
  const WeeklyDetailChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Details'),
        backgroundColor: const Color(0xFF2F5132),
        foregroundColor: Colors.white,
      ),
      body: const _WeeklyDetailChart(),
    );
  }
}

class _WeeklyDetailChart extends StatelessWidget {
  const _WeeklyDetailChart();

  @override
  Widget build(BuildContext context) {
    return Consumer<SugarProvider>(
      builder: (context, sugarProvider, child) {
        final now = DateTime.now();
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));

        final entries = sugarProvider.sugarEntries
            .map((entry) {
              final date = DateTime.parse(entry['date'] as String);
              return (
                date: date,
                grams: (entry['grams'] as num).toDouble(),
              );
            })
            .where((entry) => !entry.date.isBefore(startOfWeek))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No entries recorded for this week yet. Tap the quick log to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          );
        }

        final limit = sugarProvider.dailySugarLimit;
        final totalHours = 7 * 24.0;
        final spots = entries
            .map(
              (entry) => FlSpot(
                entry.date.difference(startOfWeek).inMinutes / 60.0,
                entry.grams,
              ),
            )
            .toList();

        final maxY = [
          limit,
          ...spots.map((spot) => spot.y),
        ].reduce((a, b) => a > b ? a : b);
        final chartMaxY = maxY == 0 ? 10.0 : maxY + (maxY * 0.15);
        final horizontalInterval = () {
          if (chartMaxY <= 0) return 5.0;
          final interval = chartMaxY / 4;
          return interval < 5 ? 5.0 : interval;
        }();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tap any point to view the exact time and amount.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 320,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: totalHours,
                    minY: 0,
                    maxY: chartMaxY,
                    gridData: FlGridData(
                      show: true,
                      horizontalInterval: horizontalInterval,
                      verticalInterval: 24,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        dashArray: const [5, 5],
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                      ),
                    ),
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: limit,
                          dashArray: const [4, 4],
                          color: const Color(0xFFF2A93B),
                          strokeWidth: 2,
                          label: HorizontalLineLabel(
                            show: true,
                            alignment: Alignment.topLeft,
                            labelResolver: (_) => 'Daily limit (${limit.toStringAsFixed(0)}g)',
                            style: const TextStyle(
                              color: Color(0xFFF2A93B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 48,
                          getTitlesWidget: (value, meta) => Text(
                            value.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 24,
                          getTitlesWidget: (value, meta) {
                            final date = startOfWeek.add(Duration(hours: value.toInt()));
                            return Transform.translate(
                              offset: const Offset(0, 8),
                              child: Text(
                                DateFormat('E\nha').format(date),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black54,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.white,
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((touchedSpot) {
                            final date = startOfWeek.add(
                              Duration(
                                minutes: (touchedSpot.x * 60).round(),
                              ),
                            );
                            return LineTooltipItem(
                              '${DateFormat('EEE, MMM d – h:mma').format(date)}\n'
                              '${touchedSpot.y.toStringAsFixed(1)} g',
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
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        barWidth: 3,
                        color: const Color(0xFF6ABF69),
                        isStrokeCapRound: true,
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF6ABF69).withOpacity(0.15),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            final isOverLimit = spot.y > limit;
                            return FlDotCirclePainter(
                              radius: 5,
                              color: isOverLimit
                                  ? const Color(0xFFF2A93B)
                                  : const Color(0xFF6ABF69),
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
