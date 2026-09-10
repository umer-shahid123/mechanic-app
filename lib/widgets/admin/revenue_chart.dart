import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class RevenueChart extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final bool isDark;

  const RevenueChart({super.key, required this.transactions, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Process transactions to get daily revenue for the last 7 days
    final now = DateTime.now();
    final Map<int, double> dailyRevenue = {};
    
    // Initialize last 7 days
    for (int i = 0; i < 7; i++) {
      dailyRevenue[now.subtract(Duration(days: i)).weekday] = 0;
    }

    for (var tx in transactions) {
      if (tx['type'] == 'payout') {
        final date = DateTime.parse(tx['created_at']);
        if (now.difference(date).inDays < 7) {
          dailyRevenue[date.weekday] = (dailyRevenue[date.weekday] ?? 0) + (tx['amount'] as num).toDouble();
        }
      }
    }

    final spots = dailyRevenue.entries.map((e) => FlSpot(e.key.toDouble(), e.value / 1000)).toList();
    spots.sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots.isEmpty ? [const FlSpot(0, 0), const FlSpot(6, 0)] : spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                isDark ? AppColors.neonGreen : AppColors.primary,
                isDark ? Colors.cyanAccent : Colors.teal,
              ],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.2),
                  (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
