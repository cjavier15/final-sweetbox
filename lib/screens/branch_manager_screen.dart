import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class BranchManagerScreen extends StatefulWidget {
  const BranchManagerScreen({super.key});

  @override
  State<BranchManagerScreen> createState() => _BranchManagerScreenState();
}

class _BranchManagerScreenState extends State<BranchManagerScreen> {
  int _selectedIndex = 0;
  final FirestoreService _firestore = FirestoreService();

  @override
  void initState() {
    super.initState();
    _listenForLowStock();
  }

  void _listenForLowStock() {
    // This keeps your live popup snackbar functional
    FirebaseFirestore.instance
        .collection('inventory')
        .where('currentStock', isLessThanOrEqualTo: 15.0)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          var item = change.doc.data() as Map<String, dynamic>;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ Alert: ${item['name']} is running low!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    });
  }

  // KPIs and Sales Data (Still mocked for now, but UI is responsive)
  final List<Map<String, dynamic>> _kpis = [
    {
      'label': 'Daily Revenue',
      'value': '₱ 24,850',
      'change': '+12.4%',
      'up': true,
      'icon': Icons.attach_money,
      'color': AppColors.success
    },
    {
      'label': 'Inventory Status',
      'value': '78%',
      'change': '-3.2%',
      'up': false,
      'icon': Icons.inventory_2_outlined,
      'color': AppColors.warning
    },
    {
      'label': 'Pending Actions',
      'value': '5',
      'change': '+2',
      'up': false,
      'icon': Icons.pending_actions_outlined,
      'color': AppColors.danger
    },
    {
      'label': 'Turnover Ratio',
      'value': '4.2x',
      'change': '+0.3x',
      'up': true,
      'icon': Icons.loop,
      'color': AppColors.info
    },
  ];

  final List<Map<String, dynamic>> _salesData = [
    {'day': 'Mon', 'value': 18500},
    {'day': 'Tue', 'value': 22300},
    {'day': 'Wed', 'value': 19800},
    {'day': 'Thu', 'value': 24850},
    {'day': 'Fri', 'value': 28000},
    {'day': 'Sat', 'value': 32000},
    {'day': 'Sun', 'value': 29500},
  ];

  final List<String> _navItems = ['Dashboard', 'Sales', 'Inventory'];
  final List<IconData> _navIcons = [
    Icons.dashboard_outlined,
    Icons.point_of_sale_outlined,
    Icons.inventory_2_outlined
  ];

  void _handleNavigation(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
      Navigator.pushNamed(context, '/enterprise');
      setState(() => _selectedIndex = 0);
    } else if (index == 2) {
      Navigator.pushNamed(context, '/inventory');
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? 'Branch Manager';
    final branchName = args?['branch'] ?? 'Ibaan';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Text('$branchName Branch',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontSize: 11,
                    )),
          ],
        ),
        leading: Builder(
          builder: (context) {
            if (MediaQuery.of(context).size.width < 900) {
              return IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
            );
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false))
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile) _buildDesktopSidebar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- RESPONSIVE KPI GRID ---
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 250,
                          childAspectRatio: 1.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _kpis.length,
                        itemBuilder: (context, index) {
                          final kpi = _kpis[index];
                          return _buildKpiCard(kpi);
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- RESPONSIVE 7-DAY TREND ---
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('7-Day Sales Trend',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              Text('Daily revenue | $branchName Branch',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 140,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: _salesData.map((data) {
                                    const maxValue = 32000;
                                    final height =
                                        (data['value'] / maxValue * 100)
                                            .toDouble();
                                    final isToday = data['day'] == 'Thu';

                                    return Flexible(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              '${(data['value'] / 1000).toStringAsFixed(1)}K',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isToday
                                                    ? AppColors.accent
                                                    : AppColors.textSecondary,
                                                fontWeight: isToday
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Flexible(
                                            child: Container(
                                              width: 24,
                                              height: height,
                                              decoration: BoxDecoration(
                                                color: isToday
                                                    ? AppColors.accent
                                                    : AppColors.primary
                                                        .withOpacity(0.3),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        top:
                                                            Radius.circular(4)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['day'],
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isToday
                                                  ? AppColors.primary
                                                  : AppColors.textSecondary,
                                              fontWeight: isToday
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Live Low Stock Alerts',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),

                      // --- REAL-TIME RESPONSIVE ALERTS ---
                      StreamBuilder<List<RawMaterial>>(
                        stream: _firestore.streamInventory(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(),
                            ));
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No inventory data available.'),
                              ),
                            );
                          }

                          // Filter items that are running low.
                          // You can adjust the 15.0 threshold logic to match your business rules.
                          final double threshold = 15.0;
                          final lowStockItems = snapshot.data!
                              .where((item) => item.currentStock <= threshold)
                              .toList();

                          if (lowStockItems.isEmpty) {
                            return Card(
                              color: AppColors.success.withOpacity(0.1),
                              elevation: 0,
                              child: const ListTile(
                                leading: Icon(Icons.check_circle,
                                    color: AppColors.success),
                                title: Text('All inventory levels are healthy.',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600)),
                              ),
                            );
                          }

                          return Column(
                            children: lowStockItems.map((item) {
                              // If stock is below 30% of the threshold, mark it as critical
                              final severity =
                                  item.currentStock <= (threshold * 0.3)
                                      ? 'critical'
                                      : 'low';
                              return _buildAlertCard({
                                'ingredient': item.name,
                                'available':
                                    item.currentStock.toStringAsFixed(1) +
                                        ' ' +
                                        item.unit,
                                'threshold': threshold.toStringAsFixed(1) +
                                    ' ' +
                                    item.unit,
                                'severity': severity,
                              });
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(child: SafeArea(child: _buildMobileNav()))
          : null,
    );
  }

  Widget _buildKpiCard(Map<String, dynamic> kpi) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    kpi['label'],
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(kpi['icon'] as IconData,
                    size: 18, color: kpi['color'] as Color),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                kpi['value'],
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kpi['color'] as Color),
              ),
            ),
            Row(
              children: [
                Icon(kpi['up'] ? Icons.trending_up : Icons.trending_down,
                    size: 14,
                    color: kpi['up'] ? AppColors.success : AppColors.danger),
                const SizedBox(width: 4),
                Text(kpi['change'],
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            kpi['up'] ? AppColors.success : AppColors.danger)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return Container(
      width: 80,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 16),
          ...List.generate(
              _navItems.length,
              (index) => GestureDetector(
                    onTap: () => _handleNavigation(index),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedIndex == index
                            ? AppColors.accent.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Icon(_navIcons[index],
                              color: _selectedIndex == index
                                  ? AppColors.accent
                                  : Colors.white54,
                              size: 24),
                          const SizedBox(height: 4),
                          Text(_navItems[index],
                              style: TextStyle(
                                  color: _selectedIndex == index
                                      ? AppColors.accent
                                      : Colors.white54,
                                  fontSize: 10),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )),
        ],
      ),
    );
  }

  Widget _buildMobileNav() {
    return ListView(
      children: List.generate(
          _navItems.length,
          (index) => ListTile(
                leading: Icon(_navIcons[index],
                    color: _selectedIndex == index
                        ? AppColors.accent
                        : AppColors.primary),
                title: Text(_navItems[index]),
                selected: _selectedIndex == index,
                onTap: () {
                  Navigator.pop(context);
                  _handleNavigation(index);
                },
              )),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final color = severity == 'critical' ? AppColors.danger : AppColors.warning;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.warning_amber_rounded, color: color, size: 28),
        title: Text(alert['ingredient'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
            '${alert['available']} available / ${alert['threshold']} min',
            style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
