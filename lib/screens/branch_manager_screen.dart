import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BranchManagerScreen extends StatefulWidget {
  const BranchManagerScreen({super.key});

  @override
  State<BranchManagerScreen> createState() => _BranchManagerScreenState();
}

class _BranchManagerScreenState extends State<BranchManagerScreen> {
  int _selectedIndex = 0;

  final List<Map<String, dynamic>> _kpis = [
    {'label': 'Daily Revenue', 'value': '₱24,850', 'change': '+12.4%', 'up': true, 'icon': Icons.attach_money, 'color': AppColors.success},
    {'label': 'Inventory Status', 'value': '78%', 'change': '-3.2%', 'up': false, 'icon': Icons.inventory_2_outlined, 'color': AppColors.warning},
    {'label': 'Pending Actions', 'value': '5', 'change': '+2', 'up': false, 'icon': Icons.pending_actions_outlined, 'color': AppColors.danger},
    {'label': 'Turnover Ratio', 'value': '4.2x', 'change': '+0.3x', 'up': true, 'icon': Icons.loop, 'color': AppColors.info},
  ];

  final List<Map<String, dynamic>> _productionTargets = [
    {'product': 'Chocolate Cake', 'recommended': 18, 'justification': 'High demand + Lipa Fiesta in 3 days', 'status': 'pending'},
    {'product': 'Red Velvet Cake', 'recommended': 12, 'justification': 'Steady demand, current stock sufficient', 'status': 'approved'},
    {'product': 'Cheese Roll', 'recommended': 60, 'justification': 'Best-selling item, maintain buffer', 'status': 'pending'},
    {'product': 'Ensaymada', 'recommended': 8, 'justification': 'Slow-moving, reduce production', 'status': 'overridden'},
  ];

  final List<Map<String, dynamic>> _lowStockAlerts = [
    {'ingredient': 'All-Purpose Flour', 'available': '4.5 kg', 'threshold': '8.0 kg', 'severity': 'critical'},
    {'ingredient': 'Heavy Cream', 'available': '1.0 L', 'threshold': '3.0 L', 'severity': 'critical'},
    {'ingredient': 'Butter', 'available': '3.2 kg', 'threshold': '5.0 kg', 'severity': 'low'},
    {'ingredient': 'Milk', 'available': '8.0 L', 'threshold': '10.0 L', 'severity': 'low'},
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

  final List<String> _navItems = ['Dashboard', 'Sales', 'Inventory', 'Prescriptions'];
  final List<IconData> _navIcons = [
    Icons.dashboard_outlined,
    Icons.bar_chart_outlined,
    Icons.inventory_2_outlined,
    Icons.auto_awesome_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? 'Branch Manager';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Branch Manager'),
            Text(
              'Sampaguita Lipa Branch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.accent,
                fontSize: 11,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/login');
            }
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.accent,
              radius: 16,
              child: Text(
                role == 'Business Owner' ? 'BO' : 'BM',
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              return Row(
                children: [
                  if (!isMobile)
                    Container(
                  width: 70,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        ...List.generate(_navItems.length, (index) => GestureDetector(
                          onTap: () {
                            if (index == 3) {
                              Navigator.pushNamed(context, '/prescriptions', arguments: {'role': role});
                            } else {
                              setState(() => _selectedIndex = index);
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedIndex == index
                                  ? AppColors.accent.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedIndex == index ? AppColors.accent : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(_navIcons[index],
                                    color: _selectedIndex == index ? AppColors.accent : Colors.white54,
                                    size: 22),
                                const SizedBox(height: 4),
                                Text(
                                  _navItems[index],
                                  style: TextStyle(
                                    color: _selectedIndex == index ? AppColors.accent : Colors.white54,
                                    fontSize: 8,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thursday, May 11, 2025', style: Theme.of(context).textTheme.bodyMedium),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isMobile ? 1 : 2,
                          childAspectRatio: isMobile ? 1.45 : 1.6,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _kpis.length,
                        itemBuilder: (context, index) {
                          final kpi = _kpis[index];
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(kpi['label'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                      Icon(kpi['icon'] as IconData, size: 18, color: kpi['color'] as Color),
                                    ],
                                  ),
                                  Text(
                                    kpi['value'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: kpi['color'] as Color,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        kpi['up'] ? Icons.trending_up : Icons.trending_down,
                                        size: 14,
                                        color: kpi['up'] ? AppColors.success : AppColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        kpi['change'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kpi['up'] ? AppColors.success : AppColors.danger,
                                        ),
                                      ),
                                      const Text(' vs yesterday', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('7-Day Sales Trend', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 4),
                              const Text('Daily revenue — Sampaguita Lipa Branch', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 120,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: _salesData.map((data) {
                                    const maxValue = 32000;
                                    final height = (data['value'] / maxValue * 100).toDouble();
                                    final isToday = data['day'] == 'Thu';
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₱${(data['value'] / 1000).toStringAsFixed(0)}K',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isToday ? AppColors.accent : AppColors.textSecondary,
                                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 28,
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: isToday ? AppColors.accent : AppColors.primary.withValues(alpha: 0.3),
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          data['day'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isToday ? AppColors.primary : AppColors.textSecondary,
                                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('AI Production Targets', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/prescriptions'),
                            child: const Text('View All', style: TextStyle(color: AppColors.accent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._productionTargets.map((target) => _buildProductionCard(target)),
                      const SizedBox(height: 16),
                      Text('Low Stock Alerts', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ..._lowStockAlerts.map((alert) => _buildAlertCard(alert)),
                    ],
                  ),
                ),
              ),
                ],
              );
            },
          ),
        ],
      ),
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(child: SafeArea(child: _buildMobileNav(role)))
          : null,
    );
  }

  Widget _buildMobileNav(String role) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Navigation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        ...List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          return ListTile(
            leading: Icon(_navIcons[index]),
            title: Text(item),
            onTap: () {
              if (index == 3) {
                Navigator.pushNamed(context, '/prescriptions', arguments: {'role': role});
              } else {
                setState(() => _selectedIndex = index);
                Navigator.pop(context);
              }
            },
          );
        }),
      ],
    );
  }

  Widget _buildProductionCard(Map<String, dynamic> target) {
    final status = target['status'] as String;
    Color statusColor = status == 'approved'
        ? AppColors.success
        : status == 'pending' ? AppColors.warning : AppColors.info;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(target['product'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.accent),
                const SizedBox(width: 4),
                Text('Recommended: ${target['recommended']} units',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Text(target['justification'],
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            if (status == 'pending') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => target['status'] = 'overridden'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Override', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => target['status'] = 'approved'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Approve', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final severity = alert['severity'] as String;
    final color = severity == 'critical' ? AppColors.danger : AppColors.warning;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.warning_amber_rounded, color: color, size: 20),
        ),
        title: Text(alert['ingredient'],
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${alert['available']} available / ${alert['threshold']} min',
            style: const TextStyle(fontSize: 11)),
        trailing: TextButton(
          onPressed: () => Navigator.pushNamed(context, '/prescriptions'),
          child: const Text('View Rx', style: TextStyle(color: AppColors.accent, fontSize: 12)),
        ),
      ),
    );
  }
}
