import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sugar_provider.dart';
import '../screens/weekly_detail_chart_screen.dart';

class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SugarProvider>(
      builder: (context, sugarProvider, child) {
        final weeklyData = sugarProvider.getWeeklySugar();
        final limit = sugarProvider.dailySugarLimit;
        final entriesList = weeklyData.entries.toList();
        final allSpots = entriesList
            .map((entry) => FlSpot(
                  _getDayIndex(entry.key).toDouble(),
                  entry.value.isFinite ? entry.value : 0.0,
                ))
            .toList();


        // Segment the line into under/over-limit continuous segments.
        // Insert a crossing point where the line passes the limit so color change is seamless.
        final List<List<FlSpot>> underSegments = [];
        final List<List<FlSpot>> overSegments = [];
        if (allSpots.isNotEmpty) {
          List<FlSpot> current = [];
          bool currentOver = allSpots.first.y > limit;
          current.add(allSpots.first);
          for (int i = 1; i < allSpots.length; i++) {
            final prev = allSpots[i - 1];
            final curr = allSpots[i];
            final prevOver = prev.y > limit;
            final currOver = curr.y > limit;
            if (prevOver != currOver) {
              // Compute crossing point between prev and curr at y=limit
              final dy = curr.y - prev.y;
              final dx = curr.x - prev.x;
              final t = dy == 0 ? 0.0 : (limit - prev.y) / dy;
              final crossX = prev.x + (dx * t);
              final cross = FlSpot(crossX, limit);
              current.add(cross);
              // Push finished segment
              if (currentOver) {
                overSegments.add(List<FlSpot>.from(current));
              } else {
                underSegments.add(List<FlSpot>.from(current));
              }
              // Start new segment from crossing
              current = [cross, curr];
              currentOver = currOver;
            } else {
              current.add(curr);
            }
          }
          // Push the last segment
          if (current.isNotEmpty) {
            if (currentOver) {
              overSegments.add(current);
            } else {
              underSegments.add(current);
            }
          }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F5132),
                ),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const WeeklyDetailChartScreen(),
                      ),
                    );
                  },
                  child: SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                                return Text(
                                  days[value.toInt()],
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          // Under-limit green segments
                          for (final seg in underSegments)
                            LineChartBarData(
                              spots: seg,
                              isCurved: true,
                              color: const Color(0xFF6ABF69),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFF6ABF69),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFF6ABF69).withOpacity(0.1),
                              ),
                            ),
                          // Over-limit orange segments
                          for (final seg in overSegments)
                            LineChartBarData(
                              spots: seg,
                              isCurved: true,
                              color: const Color(0xFFF2A93B),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: const Color(0xFFF2A93B),
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFF2A93B).withOpacity(0.1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem('Under Limit', const Color(0xFF6ABF69)),
                  _buildLegendItem('Over Limit', const Color(0xFFF2A93B)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _getDayIndex(String day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.indexOf(day);
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
