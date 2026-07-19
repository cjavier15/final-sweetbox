import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class EnterpriseDashboardScreen extends StatefulWidget {
  const EnterpriseDashboardScreen({super.key});

  @override
  State<EnterpriseDashboardScreen> createState() =>
      _EnterpriseDashboardScreenState();
}

class _EnterpriseDashboardScreenState extends State<EnterpriseDashboardScreen> {
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enterprise Analytics Module')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestore.streamTransactions(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final transactionHistory = snapshot.data!;
          double liveRevenue = transactionHistory.fold(0.0,
              (sum, tx) => sum + ((tx['totalAmount'] ?? 0) as num).toDouble());

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryDeck(
                      liveRevenue, transactionHistory.length, isMobile),
                  const SizedBox(height: 24),
                  Text('Real-Time Revenue Performance Curve',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildGraphicalAnalyticsView(transactionHistory),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Widget _buildSummaryDeck(
      double totalRev, int totalSalesCount, bool isMobile) {
    // Use Flex to switch between Row (desktop) and Column (mobile) smoothly
    return Flex(
      direction: isMobile ? Axis.vertical : Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Card(
            color: AppColors.primary,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gross Running Revenue',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(' ${totalRev.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 0 : 12, height: isMobile ? 12 : 0),
        Flexible(
          fit: FlexFit.loose,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consolidated Tickets',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('$totalSalesCount Orders',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGraphicalAnalyticsView(List<Map<String, dynamic>> dataPoints) {
    if (dataPoints.isEmpty) {
      return const SizedBox(
          height: 200,
          child: Center(child: Text('Awaiting transactional data updates...')));
    }

    List<FlSpot> plots = [];
    double indexCount = 0;

    for (var tx in dataPoints.reversed) {
      plots.add(FlSpot(indexCount, (tx['totalAmount'] as num).toDouble()));
      indexCount += 1.0;
    }

    return LayoutBuilder(builder: (context, constraints) {
      final chartHeight = constraints.maxWidth > 600 ? 350.0 : 240.0;
      return Container(
        height: chartHeight,
        padding: const EdgeInsets.only(right: 24, top: 16, bottom: 8),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: const FlTitlesData(
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: plots,
                isCurved: true,
                barWidth: 3,
                color: AppColors.accent,
                belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.accent.withValues(alpha: 0.15)),
                dotData: const FlDotData(show: true),
              )
            ],
          ),
        ),
      );
    });
  }
}
