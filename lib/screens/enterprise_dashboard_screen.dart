import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
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
              final isMobile = constraints.maxWidth < 768;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryDeck(
                      liveRevenue, transactionHistory.length, isMobile),
                  const SizedBox(height: 24),
                  Text('Real-Time Revenue Performance',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _buildLineChartCard(transactionHistory, constraints.maxWidth),
                  const SizedBox(height: 24),

                  // NEW: Additional Responsive Charts
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: isMobile
                            ? double.infinity
                            : (constraints.maxWidth / 2) - 24,
                        child: _buildPaymentMethodsPieChart(transactionHistory),
                      ),
                      SizedBox(
                        width: isMobile
                            ? double.infinity
                            : (constraints.maxWidth / 2) - 24,
                        child:
                            _buildTransactionVolumeBarChart(transactionHistory),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gross Running Revenue',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('₱ ${totalRev.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: isMobile ? 0 : 16, height: isMobile ? 16 : 0),
        Flexible(
          fit: FlexFit.loose,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Consolidated Tickets',
                      style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('$totalSalesCount Orders',
                      style: const TextStyle(
                          fontSize: 28,
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

  Widget _buildLineChartCard(
      List<Map<String, dynamic>> dataPoints, double maxWidth) {
    if (dataPoints.isEmpty) return const _EmptyChartState();

    List<FlSpot> plots = [];
    for (int i = 0; i < dataPoints.length; i++) {
      plots.add(FlSpot(i.toDouble(),
          (dataPoints.reversed.toList()[i]['totalAmount'] as num).toDouble()));
    }

    final chartHeight = maxWidth > 600 ? 350.0 : 240.0;

    return Card(
      elevation: 2,
      child: Container(
        height: chartHeight,
        padding:
            const EdgeInsets.only(right: 24, top: 24, bottom: 12, left: 12),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true, drawVerticalLine: false),
            titlesData: const FlTitlesData(
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: plots,
                isCurved: true,
                barWidth: 3,
                color: AppColors.accent,
                belowBarData: BarAreaData(
                    show: true, color: AppColors.accent.withOpacity(0.15)),
                dotData: const FlDotData(show: false),
              )
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Pie Chart for Payment Methods
  Widget _buildPaymentMethodsPieChart(List<Map<String, dynamic>> dataPoints) {
    if (dataPoints.isEmpty) return const _EmptyChartState();

    int cash = 0, gcash = 0, card = 0;
    for (var tx in dataPoints) {
      String pm = (tx['paymentMethod'] ?? 'Cash').toString().toLowerCase();
      if (pm.contains('gcash') || pm.contains('e-wallet'))
        gcash++;
      else if (pm.contains('card'))
        card++;
      else
        cash++;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Preferences',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: AppColors.accent,
                      value: cash.toDouble(),
                      title: 'Cash\n$cash',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: AppColors.info,
                      value: gcash.toDouble(),
                      title: 'E-Wallet\n$gcash',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: AppColors.success,
                      value: card.toDouble(),
                      title: 'Card\n$card',
                      radius: 50,
                      titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Bar Chart for Order Volume
  Widget _buildTransactionVolumeBarChart(
      List<Map<String, dynamic>> dataPoints) {
    if (dataPoints.isEmpty) return const _EmptyChartState();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Volume Profile',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 15, // Arbitrary max for visualization
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: List.generate(
                    7,
                    (index) => BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (dataPoints.length > index
                                  ? (index * 1.5 + 2)
                                  : 0)
                              .toDouble(), // Mock historical distribution
                          color: AppColors.primary.withOpacity(0.8),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChartState extends StatelessWidget {
  const _EmptyChartState();
  @override
  Widget build(BuildContext context) {
    return const Card(
      child: SizedBox(
        height: 200,
        child: Center(child: Text('Awaiting transactional data...')),
      ),
    );
  }
}
