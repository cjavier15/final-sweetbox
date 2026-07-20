import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> processCheckout({
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required String paymentMethod,
    required bool appliedDiscount,
    required bool isRefund,
  }) async {
    final Map<String, int> productQuantities = {};

    for (var item in cartItems) {
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

          // --- INVENTORY SAFEGUARD LOGIC ---
          // Halts the checkout if this transaction will result in negative stock.
          if (!isRefund && (currentStock - aggregateDeduction < 0)) {
            final ingredientName = invDoc.get('name');
            throw Exception(
                'Insufficient stock for $ingredientName. Need $aggregateDeduction but only have $currentStock left.');
          }
          // ---------------------------------

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
}
