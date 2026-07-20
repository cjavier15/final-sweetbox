import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _firestore = FirestoreService();

  // Filter State
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  final List<String> _categories = [
    'All',
    'Raw Ingredients',
    'Flavorings',
    'Fillings'
  ];
  final List<String> _statuses = ['All', 'In Stock', 'Low Stock', 'Critical'];

  @override
  void initState() {
    super.initState();
    _listenForLowStock();
  }

  void _listenForLowStock() {
    FirebaseFirestore.instance
        .collection('inventory')
        .where('stock', isLessThanOrEqualTo: 10)
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

  // Helper to determine status based on mock/actual thresholds
  String _getItemStatus(double currentStock, double threshold) {
    if (currentStock <= threshold * 0.5) return 'Critical';
    if (currentStock <= threshold) return 'Low Stock';
    return 'In Stock';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Inventory & Supply Chain'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false),
          )
        ],
      ),
      body: StreamBuilder<List<RawMaterial>>(
        stream: _firestore.streamInventory(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final allMaterials = snapshot.data!;

          // Apply Filters
          final filteredMaterials = allMaterials.where((material) {
            // Note: Replace with actual material.category & material.threshold once added to model
            final double threshold = 15.0;
            final String category = 'Raw Ingredients';
            final String status =
                _getItemStatus(material.currentStock, threshold);

            final matchesCategory =
                _selectedCategory == 'All' || category == _selectedCategory;
            final matchesStatus =
                _selectedStatus == 'All' || status == _selectedStatus;

            return matchesCategory && matchesStatus;
          }).toList();

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;
              final isMobile = constraints.maxWidth < 650;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isDesktop) _buildSidebar(),
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScorecards(allMaterials, isMobile),
                          const SizedBox(height: 24),
                          _buildFilters(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: isMobile
                                ? _buildMobileList(filteredMaterials)
                                : _buildDataTable(filteredMaterials),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showActionMenu,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.menu_open, color: AppColors.primary),
        label: const Text('Actions',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // =========================================================================
  // TOP LEVEL UI: SCORECARDS & FILTERS
  // =========================================================================

  Widget _buildScorecards(List<RawMaterial> items, bool isMobile) {
    int inStock = 0;
    int lowStock = 0;
    int critical = 0;

    for (var item in items) {
      double threshold = 15.0; // Fallback threshold
      String status = _getItemStatus(item.currentStock, threshold);
      if (status == 'In Stock') inStock++;
      if (status == 'Low Stock') lowStock++;
      if (status == 'Critical') critical++;
    }

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _scorecard('Total Items', items.length.toString(), AppColors.primary,
            Icons.inventory_2),
        _scorecard('In Stock', inStock.toString(), AppColors.success,
            Icons.check_circle),
        _scorecard('Low Stock', lowStock.toString(), AppColors.warning,
            Icons.warning_amber_rounded),
        _scorecard('Critical', critical.toString(), AppColors.danger,
            Icons.error_outline),
      ],
    );
  }

  Widget _scorecard(String title, String value, Color color, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        const Text('Filter by: ',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(width: 12),
        _dropdownFilter(
          value: _selectedCategory,
          items: _categories,
          onChanged: (val) => setState(() => _selectedCategory = val!),
        ),
        const SizedBox(width: 16),
        _dropdownFilter(
          value: _selectedStatus,
          items: _statuses,
          onChanged: (val) => setState(() => _selectedStatus = val!),
        ),
      ],
    );
  }

  Widget _dropdownFilter(
      {required String value,
      required List<String> items,
      required Function(String?) onChanged}) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.primary,
              fontWeight: FontWeight.w500),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 70,
      color: AppColors.primary,
      child: Column(
        children: [
          const SizedBox(height: 20),
          IconButton(
              icon: const Icon(Icons.inventory_2, color: Colors.white),
              onPressed: () {}),
        ],
      ),
    );
  }

  // =========================================================================
  // RESPONSIVE LAYOUTS (Tables & Cards)
  // =========================================================================

  Widget _buildDataTable(List<RawMaterial> items) {
    if (items.isEmpty)
      return const Center(child: Text("No items match your filters."));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Expanded(flex: 3, child: _headerText('Item Name')),
              Expanded(flex: 2, child: _headerText('Category')),
              Expanded(flex: 1, child: _headerText('Unit')),
              Expanded(flex: 2, child: _headerText('Stock Level')),
              Expanded(flex: 1, child: _headerText('Threshold')),
            ],
          ),
        ),
        const Divider(color: AppColors.divider, thickness: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: items.length,
            separatorBuilder: (context, index) => const Divider(
                color: AppColors.divider, thickness: 0.5, height: 1),
            itemBuilder: (context, index) {
              final material = items[index];
              final double threshold = 15.0;
              final String category = 'Raw Ingredients';

              return InkWell(
                onTap: () => _openEditDialog(material),
                hoverColor: Colors.black.withOpacity(0.02),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(material.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildCategoryChip(category)),
                      ),
                      Expanded(
                          flex: 1,
                          child: Text(material.unit,
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          flex: 2,
                          child: _buildStockLevelIndicator(
                              material.currentStock, threshold,
                              isMobile: false)),
                      Expanded(
                          flex: 1,
                          child: Text(threshold.toStringAsFixed(0),
                              style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileList(List<RawMaterial> items) {
    if (items.isEmpty)
      return const Center(child: Text("No items match your filters."));

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final material = items[index];
        final double threshold = 15.0;
        final String category = 'Raw Ingredients';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.divider, width: 1)),
          child: InkWell(
            onTap: () => _openEditDialog(material),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(material.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary))),
                      _buildCategoryChip(category),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Unit: ${material.unit}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                      Text('Threshold: ${threshold.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildStockLevelIndicator(material.currentStock, threshold,
                      isMobile: true),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================================
  // SHARED UI COMPONENTS
  // =========================================================================

  Widget _headerText(String title) {
    return Text(title,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 14));
  }

  Widget _buildCategoryChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildStockLevelIndicator(double currentStock, double threshold,
      {required bool isMobile}) {
    String status = _getItemStatus(currentStock, threshold);
    Color statusColor = AppColors.success;
    if (status == 'Critical') statusColor = AppColors.danger;
    if (status == 'Low Stock') statusColor = AppColors.warning;

    double maxVisualStock = threshold * 2.5;
    double fillPercentage = (currentStock / maxVisualStock).clamp(0.0, 1.0);

    return Row(
      children: [
        Expanded(
          flex: isMobile ? 4 : 2,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fillPercentage,
              minHeight: 8,
              backgroundColor: AppColors.warning.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Text(
            currentStock.toStringAsFixed(currentStock % 1 == 0 ? 0 : 1),
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // ACTIONS & DIALOGS
  // =========================================================================

  void _showActionMenu() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart,
                      color: AppColors.primary),
                  title: const Text('Log Reorder Request'),
                  onTap: () {
                    Navigator.pop(context);
                    _openRestockDialog();
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.account_tree, color: AppColors.primary),
                  title: const Text('Add Product & BOM (Bill of Materials)'),
                  onTap: () {
                    Navigator.pop(context);
                    _openAddProductBOMDialog();
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        });
  }

  void _openAddProductBOMDialog() {
    final productNameController = TextEditingController();
    final productPriceController = TextEditingController();

    // List to hold dynamic rows for raw materials needed
    List<Map<String, TextEditingController>> bomItems = [
      {'name': TextEditingController(), 'qty': TextEditingController()}
    ];

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('New Product & BOM Setup'),
              content: SizedBox(
                width: 600,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 8),
                      TextField(
                          controller: productNameController,
                          decoration: const InputDecoration(
                              labelText: 'Finished Product Name',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(
                          controller: productPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Selling Price',
                              border: OutlineInputBorder())),
                      const SizedBox(height: 24),

                      const Text(
                          'Bill of Materials (Raw Ingredients needed per 1 unit)',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      const SizedBox(height: 8),

                      // Dynamic List of Materials
                      ...bomItems.asMap().entries.map((entry) {
                        int index = entry.key;
                        var item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: TextField(
                                      controller: item['name'],
                                      decoration: const InputDecoration(
                                          hintText: 'Material Name',
                                          isDense: true))),
                              const SizedBox(width: 8),
                              Expanded(
                                  flex: 2,
                                  child: TextField(
                                      controller: item['qty'],
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          hintText: 'Qty Required',
                                          isDense: true))),
                              IconButton(
                                icon: const Icon(Icons.remove_circle,
                                    color: AppColors.danger),
                                onPressed: () {
                                  if (bomItems.length > 1) {
                                    setDialogState(
                                        () => bomItems.removeAt(index));
                                  }
                                },
                              )
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Material'),
                        onPressed: () {
                          setDialogState(() {
                            bomItems.add({
                              'name': TextEditingController(),
                              'qty': TextEditingController()
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (productNameController.text.isEmpty) return;

                    // Format BOM data for database insertion
                    List<Map<String, dynamic>> formattedBOM = bomItems
                        .where((item) =>
                            item['name']!.text.isNotEmpty &&
                            item['qty']!.text.isNotEmpty)
                        .map((item) => {
                              'materialName': item['name']!.text,
                              'quantityRequired':
                                  double.tryParse(item['qty']!.text) ?? 0.0,
                            })
                        .toList();

                    // Example Firestore logic to save product + BOM
                    await FirebaseFirestore.instance
                        .collection('products')
                        .add({
                      'name': productNameController.text,
                      'price':
                          double.tryParse(productPriceController.text) ?? 0.0,
                      'bom': formattedBOM,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Product & BOM saved successfully!')));
                  },
                  child: const Text('Save Product'),
                )
              ],
            );
          });
        });
  }

  void _openEditDialog(RawMaterial material) {
    final qtyController =
        TextEditingController(text: material.currentStock.toString());
    final costController =
        TextEditingController(text: material.costPerUnit.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${material.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Current Stock'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            TextField(
                controller: costController,
                decoration: const InputDecoration(labelText: 'Cost Per Unit'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _firestore.updateInventoryItem(material.id, {
                'currentStock': double.tryParse(qtyController.text) ??
                    material.currentStock,
                'costPerUnit': double.tryParse(costController.text) ??
                    material.costPerUnit,
              });
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  void _openRestockDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Batch Restock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Material Name')),
            const SizedBox(height: 8),
            TextField(
                controller: qtyController,
                decoration: const InputDecoration(labelText: 'Target Quantity'),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Discard')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty &&
                  qtyController.text.isNotEmpty) {
                await _firestore.createRestockRequest(nameController.text,
                    double.parse(qtyController.text), 'kg');
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text('File Request'),
          )
        ],
      ),
    );
  }
}
