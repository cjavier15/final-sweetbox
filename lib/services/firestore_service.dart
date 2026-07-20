import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- INVENTORY & SCM ---
  Stream<List<RawMaterial>> streamInventory() {
    return _db
        .collection('inventory')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RawMaterial(
                  id: doc.id,
                  name: doc.get('name'),
                  currentStock: (doc.get('currentStock') as num).toDouble(),
                  unit: doc.get('unit'),
                  costPerUnit: (doc.get('costPerUnit') as num).toDouble(),
                ))
            .toList());
  }

  Future<void> updateInventoryItem(String id, Map<String, dynamic> data) async {
    await _db.collection('inventory').doc(id).update(data);
  }

  Future<void> createRestockRequest(
      String ingredientName, double quantity, String unit) async {
    await _db.collection('restock_requests').add({
      'ingredient': ingredientName,
      'quantity': quantity,
      'unit': unit,
      'status': 'pending',
      'date': DateTime.now().toIso8601String(),
    });
  }

  // --- POS & BOM ---
  Stream<List<Product>> streamProducts() {
    return _db
        .collection('products')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              var recipeList = doc.get('recipe') as List<dynamic>;
              List<BillOfMaterials> recipe = recipeList
                  .map((b) => BillOfMaterials(
                        rawMaterialId: b['rawMaterialId'],
                        quantityRequired:
                            (b['quantityRequired'] as num).toDouble(),
                      ))
                  .toList();
              return Product(
                id: doc.id,
                name: doc.get('name'),
                price: (doc.get('price') as num).toDouble(),
                category: doc.get('category'),
                recipe: recipe,
              );
            }).toList());
  }

  Future<void> processTransaction({
    required List<Map<String, dynamic>> cart,
    required double totalAmount,
    required String paymentMethod,
    required bool appliedDiscount,
    bool isRefund = false,
  }) async {
    final Map<String, int> productQuantities = {};
    for (var item in cart) {
      productQuantities[item['name']] =
          (productQuantities[item['name']] ?? 0) + (item['quantity'] as int);
    }

    return _db.runTransaction((transaction) async {
      final productSnapshots = await _db.collection('products').get();
      final inventorySnapshots = await _db.collection('inventory').get();
      final List<Map<String, dynamic>> transactionItemsJson = [];

      for (var itemEntry in productQuantities.entries) {
        final prodDoc = productSnapshots.docs
            .firstWhere((d) => d.get('name') == itemEntry.key);
        final recipeData = prodDoc.get('recipe') as List<dynamic>;

        transactionItemsJson.add({
          'productId': prodDoc.id,
          'name': itemEntry.key,
          'quantity': itemEntry.value,
          'price': prodDoc.get('price'),
        });

        for (var ingredient in recipeData) {
          final rawMaterialId = ingredient['rawMaterialId'];
          final double qtyNeededPerUnit =
              (ingredient['quantityRequired'] as num).toDouble();

          // If refund, ADD stock. If sale, DEDUCT stock.
          final double aggregateDeduction = isRefund
              ? -(qtyNeededPerUnit * itemEntry.value)
              : (qtyNeededPerUnit * itemEntry.value);

          final invDoc =
              inventorySnapshots.docs.firstWhere((i) => i.id == rawMaterialId);
          final double currentStock =
              (invDoc.get('currentStock') as num).toDouble();

          transaction.update(invDoc.reference, {
            'currentStock': currentStock - aggregateDeduction,
          });
        }
      }

      final newTxRef = _db.collection('transactions').doc();
      transaction.set(newTxRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'totalAmount': isRefund ? -totalAmount : totalAmount,
        'paymentMethod': paymentMethod,
        'appliedDiscount': appliedDiscount,
        'isRefund': isRefund,
        'items': transactionItemsJson,
      });
    });
  }

  // --- ANALYTICS ---
  Stream<List<Map<String, dynamic>>> streamTransactions() {
    return _db
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // --- SYSTEM ADMINISTRATOR (USER MANAGEMENT) ---
  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _db.collection('users').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addUser(String email, String password, String role) async {
    await _db.collection('users').add({
      'email': email,
      'password': password,
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      'active': true,
    });
  }

  Future<Map<String, dynamic>?> authenticateUser(
      String email, String password) async {
    final snapshot = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;
    return {'id': doc.id, ...doc.data()};
  }

  Future<void> deleteUser(String id) async {
    await _db.collection('users').doc(id).delete();
  }
}
