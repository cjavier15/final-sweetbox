import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../services/transaction_service.dart';
import '../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TransactionService _transactionService = TransactionService();
  late Stream<List<Product>> _productsStream;

  final List<Map<String, dynamic>> _cart = [];
  String _selectedPayment = 'Cash';
  bool _pwdDiscount = false;
  bool _isRefund = false;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Cakes',
    'Pastries',
    'Beverages',
    'Meals'
  ];

  @override
  void initState() {
    super.initState();
    _productsStream = _firestore.streamProducts();
  }

  double get _subtotal =>
      _cart.fold(0, (sum, item) => sum + (item['price'] * item['quantity']));
  double get _discount => _pwdDiscount ? _subtotal * 0.20 : 0;
  double get _total => _subtotal - _discount;

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.where((i) => i['name'] == product.name);
      if (existing.isNotEmpty) {
        existing.first['quantity']++;
      } else {
        _cart.add({
          'name': product.name,
          'price': product.price,
          'quantity': 1,
          'category': product.category
        });
      }
    });
  }

  void _removeFromCart(String name) {
    setState(() {
      final item = _cart.firstWhere((i) => i['name'] == name);
      if (item['quantity'] > 1) {
        item['quantity']--;
      } else {
        _cart.removeWhere((i) => i['name'] == name);
      }
    });
  }

  Future<void> _processTransaction() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await _transactionService.processCheckout(
        cartItems: _cart,
        totalAmount: _total,
        paymentMethod: _selectedPayment,
        appliedDiscount: _pwdDiscount,
        isRefund: _isRefund,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success),
              SizedBox(width: 12),
              Text('Transaction Confirmed'),
            ],
          ),
          content: const Text(
              'BOM components successfully deducted from central inventory store.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _cart.clear();
                  _pwdDiscount = false;
                  _isRefund = false;
                });
              },
              child: const Text('Next Order'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator

      // --- CHANGED: Now displays an Error Dialog instead of a SnackBar ---
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.danger),
              SizedBox(width: 12),
              Text('Transaction Failed',
                  style: TextStyle(color: AppColors.danger)),
            ],
          ),
          // Removes the word "Exception: " to make the error look cleaner to the user
          content: Text(e.toString().replaceAll('Exception: ', '')),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Terminal'),
        actions: [
          // REAL-TIME INVENTORY ALERT BELL
          IconButton(
            icon: const Icon(Icons.notifications_active,
                color: Colors.orangeAccent),
            tooltip: 'Check Stock Alerts',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Real-Time Stock Levels'),
                  content: SizedBox(
                    width: 400,
                    height: 500,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('inventory')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final inventoryItems = snapshot.data!.docs;
                        return ListView.builder(
                          itemCount: inventoryItems.length,
                          itemBuilder: (context, index) {
                            var item = inventoryItems[index].data()
                                as Map<String, dynamic>;
                            int reorderLevel = item['reorder_level'] ?? 10;
                            int currentStock = item['stock'] ?? 0;
                            bool isLowStock = currentStock <= reorderLevel;
                            return ListTile(
                              title: Text(item['name'] ?? 'Unknown'),
                              subtitle: Text('Stock: $currentStock'),
                              trailing: isLowStock
                                  ? const Icon(Icons.warning, color: Colors.red)
                                  : const Icon(Icons.check_circle,
                                      color: Colors.green),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    )
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20)),
              child: const Text('Ibaan Branch',
                  style: TextStyle(fontSize: 12, color: Colors.white)),
            ),
          )
        ],
      ),
      endDrawer: isMobile
          ? Drawer(
              child: SafeArea(child: _buildCartPanel(double.infinity)),
            )
          : null,
      floatingActionButton: isMobile
          ? Builder(
              builder: (context) => FloatingActionButton.extended(
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                backgroundColor: AppColors.accent,
                icon: const Icon(Icons.shopping_cart, color: AppColors.primary),
                label: Text(
                    '${_cart.length} Items | ₱ ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppColors.primary)),
              ),
            )
          : null,
      body: StreamBuilder<List<Product>>(
        stream: _productsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading products: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dynamicProducts = snapshot.data!;
          final filteredProducts = _selectedCategory == 'All'
              ? dynamicProducts
              : dynamicProducts
                  .where((p) => p.category == _selectedCategory)
                  .toList();

          return Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildCategoryRow(),
                    Expanded(child: _buildProductGrid(filteredProducts)),
                  ],
                ),
              ),
              if (!isMobile) _buildCartPanel(380),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Container(
      color: Colors.white,
      height: 65,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: _categories
            .map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.accent.withOpacity(0.9),
                    backgroundColor: AppColors.background,
                    labelStyle: TextStyle(
                        color: _selectedCategory == cat
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 220,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Card(
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _addToCart(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.fastfood,
                        color: AppColors.primary, size: 28),
                  ),
                  const Spacer(),
                  Text(
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱ ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartPanel(double width) {
    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            width: double.infinity,
            child: const Text('Current Order',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text('Cart is empty',
                        style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final item = _cart[index];
                      return ListTile(
                        title: Text(item['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('₱ ${item['price']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('x${item['quantity']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.danger),
                              onPressed: () => _removeFromCart(item['name']),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5))
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _selectedPayment,
                      underline: const SizedBox(),
                      items: ['Cash', 'Card', 'E-Wallet']
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPayment = v!),
                    ),
                  ],
                ),
                // ADDED: PWD Discount Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PWD/Senior Discount (20%)',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Switch(
                      activeColor: AppColors.accent,
                      value: _pwdDiscount,
                      onChanged: (v) => setState(() => _pwdDiscount = v),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Process as Refund',
                        style: TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600)),
                    Switch(
                      activeTrackColor: AppColors.danger.withOpacity(0.5),
                      activeColor: AppColors.danger,
                      value: _isRefund,
                      onChanged: (v) => setState(() => _isRefund = v),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // ADDED: Display the discount amount if applied
                if (_pwdDiscount)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount:',
                            style: TextStyle(color: AppColors.success)),
                        Text('- ₱ ${_discount.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppColors.success)),
                      ],
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total due:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('₱ ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : _processTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Process Checkout',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
