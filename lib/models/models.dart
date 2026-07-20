// lib/models/models.dart
class RawMaterial {
  final String id;
  final String name;
  final double currentStock;
  final String unit;
  final double costPerUnit;
  final String category; // NEW FIELD

  RawMaterial({
    required this.id,
    required this.name,
    required this.currentStock,
    required this.unit,
    required this.costPerUnit,
    this.category = 'Raw Ingredients', // DEFAULT FALLBACK
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'currentStock': currentStock,
        'unit': unit,
        'costPerUnit': costPerUnit,
        'category': category, // MAP TO FIRESTORE
      };
}

class BillOfMaterials {
  final String rawMaterialId;
  final double quantityRequired;
  
  BillOfMaterials({
    required this.rawMaterialId,
    required this.quantityRequired,
  });
  
  Map<String, dynamic> toMap() => {
        'rawMaterialId': rawMaterialId,
        'quantityRequired': quantityRequired,
      };
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final List<BillOfMaterials> recipe;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.recipe,
  });
  
  Map<String, dynamic> toMap() => {
        'name': name,
        'price': price,
        'category': category,
        'recipe': recipe.map((b) => b.toMap()).toList(),
      };
}

class OrderItem {
  final Product product;
  final int quantity;
  
  OrderItem({required this.product, required this.quantity});
  
  double get total => product.price * quantity;
}

class TransactionRecord {
  final String id;
  final DateTime timestamp;
  final List<OrderItem> items;
  final double totalAmount;
  final String cashierName;
  
  TransactionRecord({
    required this.id,
    required this.timestamp,
    required this.items,
    required this.totalAmount,
    required this.cashierName,
  });
}