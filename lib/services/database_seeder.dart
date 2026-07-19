// lib/services/database_seeder.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class DatabaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAllData() async {
    print('Starting database seed...');

    // 1. Seed Raw Materials (Inventory)
    final Map<String, Map<String, dynamic>> rawMaterials = {
      // --- ORIGINAL RAW MATERIALS ---
      'rm_flour': {
        'name': 'All-Purpose Flour',
        'currentStock': 4.5,
        'unit': 'kg',
        'costPerUnit': 45.0
      },
      'rm_sugar': {
        'name': 'Sugar',
        'currentStock': 12.0,
        'unit': 'kg',
        'costPerUnit': 50.0
      },
      'rm_butter': {
        'name': 'Butter',
        'currentStock': 3.2,
        'unit': 'kg',
        'costPerUnit': 250.0
      },
      'rm_eggs': {
        'name': 'Eggs',
        'currentStock': 48.0,
        'unit': 'pieces',
        'costPerUnit': 10.0
      },
      'rm_milk': {
        'name': 'Milk',
        'currentStock': 8.0,
        'unit': 'liters',
        'costPerUnit': 60.0
      },
      'rm_cream_cheese': {
        'name': 'Cream Cheese',
        'currentStock': 2.1,
        'unit': 'kg',
        'costPerUnit': 400.0
      },
      'rm_cocoa': {
        'name': 'Cocoa Powder',
        'currentStock': 5.5,
        'unit': 'kg',
        'costPerUnit': 200.0
      },
      'rm_heavy_cream': {
        'name': 'Heavy Cream',
        'currentStock': 1.0,
        'unit': 'liters',
        'costPerUnit': 150.0
      },

      // --- NEW RAW MATERIALS ---
      'rm_coffee_beans': {
        'name': 'Coffee Beans',
        'currentStock': 5.0,
        'unit': 'kg',
        'costPerUnit': 600.0
      },
      'rm_yeast': {
        'name': 'Active Dry Yeast',
        'currentStock': 1.5,
        'unit': 'kg',
        'costPerUnit': 180.0
      },
      'rm_vanilla': {
        'name': 'Vanilla Extract',
        'currentStock': 0.5,
        'unit': 'liters',
        'costPerUnit': 850.0
      },
      'rm_salt': {
        'name': 'Salt',
        'currentStock': 3.0,
        'unit': 'kg',
        'costPerUnit': 25.0
      },
      'rm_cinnamon': {
        'name': 'Cinnamon Powder',
        'currentStock': 1.0,
        'unit': 'kg',
        'costPerUnit': 450.0
      },
      'rm_strawberries': {
        'name': 'Fresh Strawberries',
        'currentStock': 2.0,
        'unit': 'kg',
        'costPerUnit': 350.0
      },
      'rm_matcha': {
        'name': 'Matcha Powder',
        'currentStock': 1.0,
        'unit': 'kg',
        'costPerUnit': 1200.0
      },
    };

    for (var entry in rawMaterials.entries) {
      await _db.collection('inventory').doc(entry.key).set(entry.value);
    }
    print('Inventory seeded.');

    // 2. Seed Products & Bill of Materials (POS & SCM)
    final List<Map<String, dynamic>> products = [
      // --- ORIGINAL PRODUCTS ---
      {
        'name': 'Chocolate Cake',
        'price': 485.00,
        'category': 'Cakes',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.5},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.3},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 4.0},
          {'rawMaterialId': 'rm_cocoa', 'quantityRequired': 0.2},
        ]
      },
      {
        'name': 'Red Velvet Cake',
        'price': 520.00,
        'category': 'Cakes',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.4},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.4},
          {'rawMaterialId': 'rm_cream_cheese', 'quantityRequired': 0.3},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 3.0},
        ]
      },
      {
        'name': 'Cheese Roll',
        'price': 85.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.1},
          {'rawMaterialId': 'rm_butter', 'quantityRequired': 0.05},
        ]
      },
      {
        'name': 'Iced Coffee',
        'price': 120.00,
        'category': 'Beverages',
        'recipe': [
          {'rawMaterialId': 'rm_milk', 'quantityRequired': 0.2},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.05},
        ]
      },

      // --- 10 NEW PRODUCTS ---
      {
        'name': 'Butter Croissant',
        'price': 95.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.2},
          {'rawMaterialId': 'rm_butter', 'quantityRequired': 0.1},
          {'rawMaterialId': 'rm_yeast', 'quantityRequired': 0.01},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.02},
        ]
      },
      {
        'name': 'Cinnamon Roll',
        'price': 110.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.3},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.1},
          {'rawMaterialId': 'rm_butter', 'quantityRequired': 0.05},
          {'rawMaterialId': 'rm_cinnamon', 'quantityRequired': 0.02},
          {'rawMaterialId': 'rm_cream_cheese', 'quantityRequired': 0.05},
        ]
      },
      {
        'name': 'Vanilla Cupcake',
        'price': 65.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.15},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.1},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 1.0},
          {'rawMaterialId': 'rm_butter', 'quantityRequired': 0.05},
          {'rawMaterialId': 'rm_vanilla', 'quantityRequired': 0.01},
        ]
      },
      {
        'name': 'Strawberry Shortcake',
        'price': 550.00,
        'category': 'Cakes',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.3},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.2},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 3.0},
          {'rawMaterialId': 'rm_heavy_cream', 'quantityRequired': 0.2},
          {'rawMaterialId': 'rm_strawberries', 'quantityRequired': 0.3},
        ]
      },
      {
        'name': 'Fudgy Brownies',
        'price': 80.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.2},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.3},
          {'rawMaterialId': 'rm_butter', 'quantityRequired': 0.15},
          {'rawMaterialId': 'rm_cocoa', 'quantityRequired': 0.15},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 2.0},
        ]
      },
      {
        'name': 'Matcha Latte',
        'price': 145.00,
        'category': 'Beverages',
        'recipe': [
          {'rawMaterialId': 'rm_milk', 'quantityRequired': 0.25},
          {'rawMaterialId': 'rm_matcha', 'quantityRequired': 0.02},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.02},
        ]
      },
      {
        'name': 'Classic Espresso',
        'price': 90.00,
        'category': 'Beverages',
        'recipe': [
          {'rawMaterialId': 'rm_coffee_beans', 'quantityRequired': 0.018},
        ]
      },
      {
        'name': 'Hot Cappuccino',
        'price': 135.00,
        'category': 'Beverages',
        'recipe': [
          {'rawMaterialId': 'rm_coffee_beans', 'quantityRequired': 0.018},
          {'rawMaterialId': 'rm_milk', 'quantityRequired': 0.15},
        ]
      },
      {
        'name': 'Classic Pandesal',
        'price': 45.00,
        'category': 'Pastries',
        'recipe': [
          {'rawMaterialId': 'rm_flour', 'quantityRequired': 0.25},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.05},
          {'rawMaterialId': 'rm_yeast', 'quantityRequired': 0.01},
          {'rawMaterialId': 'rm_salt', 'quantityRequired': 0.005},
        ]
      },
      {
        'name': 'New York Cheesecake',
        'price': 620.00,
        'category': 'Cakes',
        'recipe': [
          {'rawMaterialId': 'rm_cream_cheese', 'quantityRequired': 0.5},
          {'rawMaterialId': 'rm_sugar', 'quantityRequired': 0.15},
          {'rawMaterialId': 'rm_eggs', 'quantityRequired': 2.0},
          {'rawMaterialId': 'rm_heavy_cream', 'quantityRequired': 0.1},
        ]
      },
    ];

    // Clear old products first to avoid duplicates
    var oldProducts = await _db.collection('products').get();
    for (var doc in oldProducts.docs) {
      await doc.reference.delete();
    }

    for (var product in products) {
      await _db.collection('products').add(product);
    }
    print('Products seeded.');

    // 3. Seed Historical Transactions (For Enterprise Dashboard Charts)
    var oldTx = await _db.collection('transactions').get();
    for (var doc in oldTx.docs) {
      await doc.reference.delete();
    }

    final random = Random();
    final now = DateTime.now();

    // Generate 30 random transactions over the last 7 days
    for (int i = 0; i < 30; i++) {
      int daysAgo = random.nextInt(7);
      DateTime txDate =
          now.subtract(Duration(days: daysAgo, hours: random.nextInt(12)));

      // Randomize cart size and amounts
      int numItems = random.nextInt(3) + 1;
      double totalAmount = 0;
      List<Map<String, dynamic>> items = [];

      for (int j = 0; j < numItems; j++) {
        var product = products[random.nextInt(products.length)];
        int qty = random.nextInt(3) + 1;
        totalAmount += (product['price'] as double) * qty;
        items.add({
          'name': product['name'],
          'price': product['price'],
          'quantity': qty,
        });
      }

      await _db.collection('transactions').add({
        'timestamp': Timestamp.fromDate(txDate),
        'totalAmount': totalAmount,
        'paymentMethod': random.nextBool() ? 'Cash' : 'GCash',
        'appliedDiscount': false,
        'items': items,
      });
    }
    print('Historical Transactions seeded.');
    print('Database fully seeded successfully!');
  }
}
