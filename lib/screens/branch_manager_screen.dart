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

  // NEW: State variable to track the selected date filter
  DateTime? _selectedHistoryDate;

  @override
  void initState() {
    super.initState();
    _listenForLowStock();
  }

  void _listenForLowStock() {
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

  final List<String> _navItems = [
    'Dashboard',
    'History',
    'Analytics',
    'Inventory'
  ];
  final List<IconData> _navIcons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.analytics_outlined,
    Icons.inventory_2_outlined
  ];

  void _handleNavigation(int index) {
    if (index == 2) {
      Navigator.pushNamed(context, '/enterprise');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/inventory');
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // --- NEW: Helper method to open the date picker ---
  Future<void> _pickHistoryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedHistoryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedHistoryDate = picked);
    }
  }

  List<Map<String, dynamic>> _generateKPIs(
      List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    double dailyRevenue = 0;
    int ordersToday = 0;
    Map<String, int> productSales = {};

    for (var tx in transactions) {
      if (tx['timestamp'] != null) {
        DateTime txDate = (tx['timestamp'] as Timestamp).toDate();
        if (txDate.year == now.year &&
            txDate.month == now.month &&
            txDate.day == now.day) {
          dailyRevenue += (tx['totalAmount'] as num).toDouble();
          ordersToday++;

          if (tx['items'] != null) {
            for (var item in tx['items']) {
              String name = item['name'] ?? 'Unknown';
              int qty = (item['quantity'] ?? 0) as int;
              productSales[name] = (productSales[name] ?? 0) + qty;
            }
          }
        }
      }
    }

    String topItem = 'None yet';
    int topQty = 0;
    productSales.forEach((key, value) {
      if (value > topQty) {
        topQty = value;
        topItem = key;
      }
    });

    return [
      {
        'label': 'Daily Revenue',
        'value': '₱${dailyRevenue.toStringAsFixed(2)}',
        'change': 'Live',
        'up': true,
        'icon': Icons.attach_money,
        'color': AppColors.success
      },
      {
        'label': 'Orders Today',
        'value': ordersToday.toString(),
        'change': 'Live',
        'up': true,
        'icon': Icons.receipt_long,
        'color': AppColors.info
      },
      {
        'label': 'Avg Order Value',
        'value': ordersToday > 0
            ? '₱${(dailyRevenue / ordersToday).toStringAsFixed(2)}'
            : '₱0.00',
        'change': '-',
        'up': true,
        'icon': Icons.analytics_outlined,
        'color': AppColors.accent
      },
      {
        'label': 'Top Seller Today',
        'value': topItem,
        'change': '$topQty units sold',
        'up': true,
        'icon': Icons.star_border_rounded,
        'color': AppColors.warning
      }
    ];
  }

  List<Map<String, dynamic>> _generateSalesData(
      List<Map<String, dynamic>> transactions) {
    final now = DateTime.now();
    List<Map<String, dynamic>> salesData = [];

    for (int i = 6; i >= 0; i--) {
      DateTime targetDate = now.subtract(Duration(days: i));
      double dailyTotal = 0;
      for (var tx in transactions) {
        if (tx['timestamp'] != null) {
          DateTime txDate = (tx['timestamp'] as Timestamp).toDate();
          if (txDate.year == targetDate.year &&
              txDate.month == targetDate.month &&
              txDate.day == targetDate.day) {
            dailyTotal += (tx['totalAmount'] as num).toDouble();
          }
        }
      }
      String dayLabel = _getWeekdayLabel(targetDate.weekday);
      salesData.add({'day': dayLabel, 'value': dailyTotal, 'isToday': i == 0});
    }
    return salesData;
  }

  String _getWeekdayLabel(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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
                child: _selectedIndex == 0
                    ? _buildDashboardContent(branchName)
                    : _buildTransactionHistoryContent(),
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

  Widget _buildDashboardContent(String branchName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _firestore.streamTransactions(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final transactions = snapshot.data ?? [];
            final liveKpis = _generateKPIs(transactions);
            final liveSalesData = _generateSalesData(transactions);

            double maxDailyValue = 1000;
            for (var data in liveSalesData) {
              if (data['value'] > maxDailyValue) maxDailyValue = data['value'];
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: liveKpis.length,
                  itemBuilder: (context, index) =>
                      _buildKpiCard(liveKpis[index]),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('7-Day Sales Trend',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Daily revenue | $branchName Branch',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: liveSalesData.map((data) {
                              final height =
                                  (data['value'] / maxDailyValue * 100)
                                      .toDouble();
                              final isToday = data['isToday'] as bool;
                              return Flexible(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '₱${(data['value'] / 1000).toStringAsFixed(1)}K',
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
                                        height: height > 0 ? height : 2,
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? AppColors.accent
                                              : AppColors.primary
                                                  .withOpacity(0.3),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(4)),
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
                StreamBuilder<List<RawMaterial>>(
                  stream: _firestore.streamInventory(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator()));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Card(
                        child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No inventory data available.')),
                      );
                    }
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
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      );
                    }
                    return Column(
                      children: lowStockItems.map((item) {
                        final severity = item.currentStock <= (threshold * 0.3)
                            ? 'critical'
                            : 'low';
                        return _buildAlertCard({
                          'ingredient': item.name,
                          'available':
                              '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                          'threshold':
                              '${threshold.toStringAsFixed(1)} ${item.unit}',
                          'severity': severity,
                        });
                      }).toList(),
                    );
                  },
                ),
              ],
            );
          }),
    );
  }

  // --- UPDATED: Transaction History View with Date Filter ---
  // --- UPDATED: Transaction History View with Responsive Wrap ---
  Widget _buildTransactionHistoryContent() {
    return Column(
      children: [
        // Filter Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              Text(
                _selectedHistoryDate == null
                    ? 'All Transactions'
                    : 'Transactions for ${_selectedHistoryDate!.month}/${_selectedHistoryDate!.day}/${_selectedHistoryDate!.year}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_selectedHistoryDate != null)
                    TextButton.icon(
                      icon: const Icon(Icons.clear,
                          color: AppColors.danger, size: 18),
                      label: const Text('Clear',
                          style: TextStyle(color: AppColors.danger)),
                      onPressed: () =>
                          setState(() => _selectedHistoryDate = null),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Filter Date'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: _pickHistoryDate,
                  ),
                ],
              ),
            ],
          ),
        ),
        // History List
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestore.streamTransactions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No transactions found in database.'));
              }

              var transactions = snapshot.data!;

              // Apply Date Filter Logic
              if (_selectedHistoryDate != null) {
                transactions = transactions.where((tx) {
                  final date = (tx['timestamp'] as Timestamp?)?.toDate();
                  if (date == null) return false;
                  return date.year == _selectedHistoryDate!.year &&
                      date.month == _selectedHistoryDate!.month &&
                      date.day == _selectedHistoryDate!.day;
                }).toList();
              }

              if (transactions.isEmpty) {
                return const Center(
                    child:
                        Text('No transactions found for the selected date.'));
              }

              // Sort by timestamp descending (newest first)
              transactions.sort((a, b) {
                Timestamp tA = a['timestamp'] ?? Timestamp.now();
                Timestamp tB = b['timestamp'] ?? Timestamp.now();
                return tB.compareTo(tA);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  final date = (tx['timestamp'] as Timestamp?)?.toDate() ??
                      DateTime.now();
                  final formattedDate =
                      '${date.month}/${date.day}/${date.year} at ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
                  final total = (tx['totalAmount'] as num?)?.toDouble() ?? 0.0;
                  final isRefund = tx['isRefund'] ?? false;
                  final paymentMethod = tx['paymentMethod'] ?? 'Unknown';
                  final items = tx['items'] as List<dynamic>? ?? [];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: isRefund
                            ? AppColors.danger.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        child: Icon(
                          isRefund
                              ? Icons.assignment_return
                              : Icons.receipt_long,
                          color:
                              isRefund ? AppColors.danger : AppColors.success,
                        ),
                      ),
                      title: Text(
                        '${isRefund ? "Refund" : "Sale"} - $formattedDate',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      subtitle: Text(
                        'Method: $paymentMethod  |  Total: ₱${total.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isRefund
                              ? AppColors.danger
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      children: [
                        const Divider(height: 1),
                        ...items.map((item) {
                          final qty = item['quantity'] ?? 0;
                          final price =
                              (item['price'] as num?)?.toDouble() ?? 0.0;
                          final name = item['name'] ?? 'Item';
                          return ListTile(
                            dense: true,
                            title: Text('$qty x $name'),
                            trailing:
                                Text('₱${(price * qty).toStringAsFixed(2)}'),
                          );
                        }),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
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
        subtitle: Text('${alert['available']} / ${alert['threshold']} min',
            style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
