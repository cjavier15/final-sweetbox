import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          final materials = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 900;
              return Row(
                children: [
                  if (!isMobile) _buildSidebar(),
                  Expanded(child: _buildStockDeck(materials)),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRestockDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Log Reorder Request'),
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

  Widget _buildStockDeck(List<RawMaterial> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final material = items[index];
        final bool isLow = material.currentStock <=
            5.0; // Uniform rule matrix parsing threshold

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              isLow ? Icons.warning_amber_rounded : Icons.check_circle_outline,
              color: isLow ? AppColors.danger : AppColors.success,
              size: 32,
            ),
            title: Text(material.name,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle:
                Text('Unit Value: ${material.costPerUnit} / ${material.unit}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${material.currentStock.toStringAsFixed(2)} ${material.unit}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isLow ? AppColors.danger : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.accent),
                  onPressed: () => _openEditDialog(material),
                ),
              ],
            ),
          ),
        );
      },
    );
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
