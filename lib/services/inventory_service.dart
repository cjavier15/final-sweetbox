// lib/services/inventory_service.dart
import '../models/models.dart';

class InventoryService {
  // In Phase 2, this will connect directly to Firebase Firestore.
  // For now, it manages the logic of stock deduction cleanly.

  Future<void> processSale(
      TransactionRecord order, List<RawMaterial> currentInventory) async {
    for (var item in order.items) {
      int orderQty = item.quantity;

      // Look at the recipe (BOM) for each product sold
      for (var bom in item.product.recipe) {
        double totalMaterialNeeded = bom.quantityRequired * orderQty;

        // Find the raw material in the database and deduct it
        int materialIndex =
            currentInventory.indexWhere((m) => m.id == bom.rawMaterialId);
        if (materialIndex != -1) {
          RawMaterial material = currentInventory[materialIndex];

          // Deduct stock
          double updatedStock = material.currentStock - totalMaterialNeeded;

          // TODO: Push updatedStock back to Firebase Firestore
          print(
              'Deducted $totalMaterialNeeded ${material.unit} of ${material.name}. Remaining: $updatedStock');
        }
      }
    }
  }
}
