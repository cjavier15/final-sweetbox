import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';
import '../models/models.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FirestoreService _firestore = FirestoreService();
  late Stream<List<Product>> _productsStream;

  @override
  void initState() {
    super.initState();
    _productsStream = _firestore.streamProducts();
  }

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

      await _firestore.processTransaction(
        cart: _cart,
        totalAmount: _total,
        paymentMethod: _selectedPayment,
        appliedDiscount: _pwdDiscount,
        isRefund: _isRefund,
      );

      if (!mounted) return;
      Navigator.pop(context);

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
                });
              },
              child: const Text('Next Order'),
            )
          ],
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Transaction Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic breakpoint for mobile vs desktop/tablet
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Terminal'),
        actions: [
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
      // Drawer replaces the side panel on mobile screens
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
                icon: const Icon(Icons.shopping_cart),
                label: Text(
                    '${_cart.length} Items |  ${_total.toStringAsFixed(2)}'),
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
                    Expanded(
                        child: _buildProductGrid(filteredProducts,
                            MediaQuery.of(context).size.width)),
                  ],
                ),
              ),
              // Render standard side panel only on larger screens
              if (!isMobile) _buildCartPanel(360),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Container(
      color: Colors.white,
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: _categories
            .map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _selectedCategory == cat,
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                        color: _selectedCategory == cat
                            ? Colors.white
                            : AppColors.textPrimary),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, double screenWidth) {
    // Determine cross-axis count based on actual width
    int crossAxisCount = 2;
    if (screenWidth > 1200)
      crossAxisCount = 4;
    else if (screenWidth > 600) crossAxisCount = 3;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Card(
          child: InkWell(
            onTap: () => _addToCart(item),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text(' ${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.primary)),
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
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (context, index) {
                final item = _cart[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['quantity']}x @  ${item['price']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: AppColors.danger),
                    onPressed: () => _removeFromCart(item['name']),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider))),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment Method'),
                    DropdownButton<String>(
                      value: _selectedPayment,
                      items: ['Cash', 'Card', 'E-Wallet']
                          .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPayment = v!),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Process as Refund',
                        style: TextStyle(color: AppColors.danger)),
                    Switch(
                      activeColor: AppColors.danger,
                      value: _isRefund,
                      onChanged: (v) => setState(() => _isRefund = v),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('PWD Discount (20%)'),
                    Switch(
                        value: _pwdDiscount,
                        onChanged: (v) => setState(() => _pwdDiscount = v)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total due:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(' ${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cart.isEmpty ? null : _processTransaction,
                    child: Text(
                        'Process Checkout ( ${_total.toStringAsFixed(2)})'),
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
