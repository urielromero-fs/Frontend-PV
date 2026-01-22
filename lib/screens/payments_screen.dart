import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  final List<CartItem> _cartItems = [];
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _total = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cobros',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showProductSearch(context);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Product Search/Add
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF000000),
                    const Color(0xFF1a1a1a),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          hintStyle: GoogleFonts.poppins(color: Colors.white70),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                          border: InputBorder.none,
                        ),
                        style: GoogleFonts.poppins(color: Colors.white),
                        onChanged: (value) {
                          // TODO: Search products
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Categories
                    Text(
                      'Categorías Rápidas',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _CategoryChip(label: 'Bebidas', icon: Icons.local_cafe),
                        _CategoryChip(label: 'Comida', icon: Icons.restaurant),
                        _CategoryChip(label: 'Snacks', icon: Icons.cookie),
                        _CategoryChip(label: 'Otros', icon: Icons.more_horiz),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Products Grid
                    Text(
                      'Productos',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 20,
                        itemBuilder: (context, index) {
                          return _ProductCard(
                            name: 'Producto ${index + 1}',
                            price: (index + 1) * 25.50,
                            onTap: () {
                              _addToCart('Producto ${index + 1}', (index + 1) * 25.50);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Divider
          Container(
            width: 1,
            color: Colors.white.withAlpha(26),
          ),

          // Right Panel - Cart/Checkout
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF1a1a1a),
                    const Color(0xFF000000),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cart Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Carrito',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear_all, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _cartItems.clear();
                              _calculateTotals();
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Cart Items
                    Expanded(
                      child: _cartItems.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white.withAlpha(51),
                                    size: 64,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Carrito vacío',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cartItems.length,
                              itemBuilder: (context, index) {
                                return _CartItemWidget(
                                  item: _cartItems[index],
                                  onQuantityChanged: (quantity) {
                                    setState(() {
                                      if (quantity == 0) {
                                        _cartItems.removeAt(index);
                                      } else {
                                        _cartItems[index].quantity = quantity;
                                      }
                                      _calculateTotals();
                                    });
                                  },
                                  onRemove: () {
                                    setState(() {
                                      _cartItems.removeAt(index);
                                      _calculateTotals();
                                    });
                                  },
                                );
                              },
                            ),
                    ),

                    // Summary Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(13),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(26)),
                      ),
                      child: Column(
                        children: [
                          // Subtotal
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '\$${_subtotal.toStringAsFixed(2)}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Discount
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Descuento',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 80,
                                child: TextField(
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    hintStyle: GoogleFonts.poppins(color: Colors.white70),
                                    prefixText: '\$',
                                    prefixStyle: GoogleFonts.poppins(color: Colors.white70),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                                  onChanged: (value) {
                                    setState(() {
                                      _discount = double.tryParse(value) ?? 0.0;
                                      _calculateTotals();
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Total
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.white.withAlpha(26)),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'TOTAL',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${_total.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF05e265),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _cartItems.isNotEmpty ? _processPayment : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF05e265),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'COBRAR',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(String productName, double price) {
    setState(() {
      // Check if product already exists
      final existingIndex = _cartItems.indexWhere((item) => item.name == productName);
      if (existingIndex != -1) {
        _cartItems[existingIndex].quantity++;
      } else {
        _cartItems.add(CartItem(name: productName, price: price, quantity: 1));
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    _subtotal = _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    _total = _subtotal - _discount;
    if (_total < 0) _total = 0.0;
  }

  void _processPayment() {
    // TODO: Process payment
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Procesando pago de \$${_total.toStringAsFixed(2)}'),
        backgroundColor: const Color(0xFF05e265),
      ),
    );
  }

  void _showProductSearch(BuildContext context) {
    // TODO: Show advanced product search
  }
}

class CartItem {
  String name;
  double price;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
  });
}

class _ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Placeholder
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(26),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: Colors.white.withAlpha(51),
                  size: 32,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF05e265),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemWidget({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        children: [
          // Product Info
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${item.price.toStringAsFixed(2)} c/u',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            children: [
              GestureDetector(
                onTap: () => onQuantityChanged(item.quantity - 1),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(26),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${item.quantity}',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => onQuantityChanged(item.quantity + 1),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05e265),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 16),
          
          // Item Total
          Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              color: const Color(0xFF05e265),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove Button
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              color: Colors.red.withAlpha(179),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryChip({
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF05e265),
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
