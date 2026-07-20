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

  final List<Map<String, dynamic>> _lowStockAlerts = [
    {
      'ingredient': 'All-Purpose Flour',
      'available': '4.5 kg',
      'threshold': '8.0 kg',
      'severity': 'critical'
    },
    {
      'ingredient': 'Heavy Cream',
      'available': '1.0 L',
      'threshold': '3.0 L',
      'severity': 'critical'
    },
    {
      'ingredient': 'Butter',
      'available': '3.2 kg',
      'threshold': '5.0 kg',
      'severity': 'low'
    },
    {
      'ingredient': 'Milk',
      'available': '8.0 L',
      'threshold': '10.0 L',
      'severity': 'low'
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
    Icons.inventory_2_outlined,
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
    // Parse the live data attributes coming down from the user collection schema match
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final role = args?['role'] ?? 'Branch Manager';
    final branchName = args?['branch'] ?? 'Ibaan';
    final userName = args?['name'] ?? 'Manager';

    // Extract dynamic initials from the 'name' field string
    String getInitials(String name) {
      List<String> names = name.split(" ");
      String initials = "";
      if (names.isNotEmpty && names[0].isNotEmpty) {
        initials += names[0][0];
      }
      if (names.length > 1 && names[1].isNotEmpty) {
        initials += names[1][0];
      }
      return initials.isEmpty ? "BM" : initials.toUpperCase();
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role),
            Text(
              '$branchName Branch',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.accent,
                    fontSize: 11,
                  ),
            ),
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
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            );
          },
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: AppColors.accent,
              radius: 16,
              child: Text(
                getInitials(userName),
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false),
          )
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile)
                Container(
                  width: 80,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
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
                                    ? AppColors.accent.withValues(alpha: 0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedIndex == index
                                      ? AppColors.accent
                                      : Colors.transparent,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(_navIcons[index],
                                      color: _selectedIndex == index
                                          ? AppColors.accent
                                          : Colors.white54,
                                      size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    _navItems[index],
                                    style: TextStyle(
                                      color: _selectedIndex == index
                                          ? AppColors.accent
                                          : Colors.white54,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
                          Text('Tuesday, July 21, 2026',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Live',
                              style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(kpi['label'],
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary)),
                                      Icon(kpi['icon'] as IconData,
                                          size: 18,
                                          color: kpi['color'] as Color),
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
                                        kpi['up']
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        size: 14,
                                        color: kpi['up']
                                            ? AppColors.success
                                            : AppColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        kpi['change'],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: kpi['up']
                                              ? AppColors.success
                                              : AppColors.danger,
                                        ),
                                      ),
                                      Text(' vs yesterday',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textSecondary)),
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
                                height: 120,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: _salesData.map((data) {
                                    const maxValue = 32000;
                                    final height =
                                        (data['value'] / maxValue * 100)
                                            .toDouble();
                                    final isToday = data['day'] == 'Thu';
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₱${(data['value'] / 1000).toStringAsFixed(0)}K',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: isToday
                                                ? AppColors.accent
                                                : AppColors.textSecondary,
                                            fontWeight: isToday
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          width: 28,
                                          height: height,
                                          decoration: BoxDecoration(
                                            color: isToday
                                                ? AppColors.accent
                                                : AppColors.primary
                                                    .withValues(alpha: 0.3),
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(4)),
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
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text('Low Stock Alerts',
                          style: Theme.of(context).textTheme.titleMedium),
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
      drawer: MediaQuery.of(context).size.width < 900
          ? Drawer(child: SafeArea(child: _buildMobileNav()))
          : null,
    );
  }

  Widget _buildMobileNav() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 8),
        ...List.generate(_navItems.length, (index) {
          final item = _navItems[index];
          return ListTile(
            leading: Icon(_navIcons[index],
                color: _selectedIndex == index
                    ? AppColors.accent
                    : AppColors.primary),
            title: Text(item,
                style: TextStyle(
                    fontWeight: _selectedIndex == index
                        ? FontWeight.bold
                        : FontWeight.normal)),
            selected: _selectedIndex == index,
            onTap: () {
              Navigator.pop(context);
              _handleNavigation(index);
            },
          );
        }),
      ],
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
        subtitle: Text(
            '${alert['available']} available / ${alert['threshold']} min',
            style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}
