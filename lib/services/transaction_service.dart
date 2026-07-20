// lib/services/transaction_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. UPDATE THIS SIGNATURE TO USE NAMED PARAMETERS {}
  Future<void> processCheckout({
    required List<Map<String, dynamic>> cartItems,
    required double totalAmount,
    required String paymentMethod,
    required bool appliedDiscount,
    required bool isRefund,
  }) async {
    await _db.runTransaction((transaction) async {
      // ... your existing BOM deduction and inventory logic goes here ...
      // You can now also use the new variables (paymentMethod, appliedDiscount, isRefund)
      // when saving the final transaction document to Firestore!
    });
  }
}
