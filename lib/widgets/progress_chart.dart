diff --git a/lib/widgets/progress_chart.dart b/lib/widgets/progress_chart.dart
index 85326008fbf390d1f9acef5cc902a01d323a3417..ef7d53a5d346bf18583fcb4ef3b800776b4b704a 100644
--- a/lib/widgets/progress_chart.dart
+++ b/lib/widgets/progress_chart.dart
@@ -1,29 +1,30 @@
 import 'package:flutter/material.dart';
 import 'package:provider/provider.dart';
 import 'package:fl_chart/fl_chart.dart';
 import '../providers/sugar_provider.dart';
+import '../screens/weekly_detail_chart_screen.dart';
 
 class ProgressChart extends StatelessWidget {
   const ProgressChart({super.key});
 
   @override
   Widget build(BuildContext context) {
     return Consumer<SugarProvider>(
       builder: (context, sugarProvider, child) {
         final weeklyData = sugarProvider.getWeeklySugar();
         final limit = sugarProvider.dailySugarLimit;
         // Build ordered spots for the week
         final days = weeklyData.keys.toList();
         final allSpots = <FlSpot>[];
         for (int i = 0; i < days.length; i++) {
           final e = weeklyData.entries.elementAt(i);
           final x = _getDayIndex(e.key).toDouble();
           final y = e.value.isFinite ? e.value : 0.0;
           allSpots.add(FlSpot(x, y));
         }
 
         // Segment the line into under/over-limit continuous segments.
         // Insert a crossing point where the line passes the limit so color change is seamless.
         final List<List<FlSpot>> underSegments = [];
         final List<List<FlSpot>> overSegments = [];
         if (allSpots.isNotEmpty) {
diff --git a/lib/widgets/progress_chart.dart b/lib/widgets/progress_chart.dart
index 85326008fbf390d1f9acef5cc902a01d323a3417..ef7d53a5d346bf18583fcb4ef3b800776b4b704a 100644
--- a/lib/widgets/progress_chart.dart
+++ b/lib/widgets/progress_chart.dart
@@ -70,54 +71,62 @@ class ProgressChart extends StatelessWidget {
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
-              SizedBox(
-                height: 200,
-                child: LineChart(
-                  LineChartData(
+              GestureDetector(
+                onTap: () {
+                  Navigator.of(context).push(
+                    MaterialPageRoute(
+                      builder: (_) => const WeeklyDetailChartScreen(),
+                    ),
+                  );
+                },
+                child: SizedBox(
+                  height: 200,
+                  child: LineChart(
+                    LineChartData(
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
