import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class Ticket {
  final String id;
  List<CartItem> items;
  double subtotal;
  double discount;
  double total;
  DateTime createdAt;

  Ticket({
    required this.id,
    List<CartItem>? items,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    DateTime? createdAt,
  }) : 
    items = items ?? [],
    createdAt = createdAt ?? DateTime.now();
}

class _PaymentsScreenState extends State<PaymentsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Ticket> _tickets = [];
  
  // Dummy products (would come from a service/database)
  final List<Map<String, dynamic>> _products = List.generate(20, (index) => {
    'name': 'Producto ${index + 1}',
    'price': (index + 1) * 15.0,
    'isBulk': index % 5 == 0, // Every 5th item is bulk
    'image': null, // Placeholder
  });

  @override
  void initState() {
    super.initState();
    _addNewTicket();
  }

  void _addNewTicket() {
    setState(() {
      _tickets.add(Ticket(id: 'Ticket ${_tickets.length + 1}'));
      _updateTabController();
    });
  }

  void _closeTicket(int index) {
    if (_tickets.length <= 1) return; // Don't close the last ticket
    
    setState(() {
      _tickets.removeAt(index);
      _updateTabController();
    });
  }

  void _updateTabController() {
    _tabController = TabController(length: _tickets.length, vsync: this);
    _tabController.animateTo(_tickets.length - 1); // Switch to new ticket
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Ticket get currentTicket => _tickets[_tabController.index];

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
           Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _showWithdrawalDialog,
              icon: const Icon(Icons.money_off, size: 16),
              label: const Text('Salida de Efectivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Product Search/Add
          Expanded(
            flex: 3, // Increased flex for grid
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
                    // Search Bar and Categories
                     Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(26)),
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar producto...',
                                hintStyle: GoogleFonts.poppins(color: Colors.white70),
                                icon: const Icon(Icons.search, color: Colors.white70),
                                border: InputBorder.none,
                              ),
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Category Filter Buttons (Example)
                        IconButton(
                          onPressed: () {}, 
                          icon: const Icon(Icons.filter_list, color: Colors.white70),
                          tooltip: 'Filtrar',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Products Grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // More items per row for smaller cards
                          childAspectRatio: 1.0, // Square cards for compact layout
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return _ProductCard(
                            name: product['name'],
                            price: product['price'],
                            isBulk: product['isBulk'],
                            onTap: () {
                              _addToCart(product);
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

          // Right Panel - Tickets & Cart
          Expanded(
            flex: 2,
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
              child: Column(
                children: [
                  // Ticket Tabs
                  Container(
                    color: Colors.black,
                    child: Row(
                      children: [
                        Expanded(
                          child: TabBar(
                            controller: _tabController,
                            isScrollable: true,
                            indicatorColor: const Color(0xFF05e265),
                            labelColor: const Color(0xFF05e265),
                            unselectedLabelColor: Colors.white54,
                            tabs: _tickets.asMap().entries.map((entry) {
                              return Tab(
                                child: Row(
                                  children: [
                                    Text('Ticket ${entry.key + 1}'),
                                    if (_tickets.length > 1)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8.0),
                                        child: InkWell(
                                          onTap: () => _closeTicket(entry.key),
                                          child: const Icon(Icons.close, size: 16),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onTap: (index) {
                              setState(() {}); // Rebuild to show selected ticket content
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF05e265)),
                          onPressed: _addNewTicket,
                          tooltip: 'Nuevo Ticket',
                        ),
                      ],
                    ),
                  ),
                  
                  // Cart Content for Current Ticket
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Carrito',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                                onPressed: () {
                                  setState(() {
                                    currentTicket.items.clear();
                                    _calculateTotals();
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Cart Items List
                          Expanded(
                            child: currentTicket.items.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.white.withAlpha(51),
                                          size: 48,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Ticket vacío',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: currentTicket.items.length,
                                    itemBuilder: (context, index) {
                                      return _CartItemWidget(
                                        item: currentTicket.items[index],
                                        onQuantityChanged: (quantity) {
                                          setState(() {
                                            if (quantity == 0) {
                                              currentTicket.items.removeAt(index);
                                            } else {
                                              currentTicket.items[index].quantity = quantity;
                                            }
                                            _calculateTotals();
                                          });
                                        },
                                        onRemove: () {
                                          setState(() {
                                            currentTicket.items.removeAt(index);
                                            _calculateTotals();
                                          });
                                        },
                                      );
                                    },
                                  ),
                          ),
                          
                          // Summary
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(13),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withAlpha(26)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                    Text(
                                      '\$${currentTicket.total.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 24, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: currentTicket.items.isNotEmpty ? _processPayment : null,
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
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) async {
    double price = product['price'];
    double quantity = 1;
    bool isBulk = product['isBulk'] ?? false;

    if (isBulk) {
      final result = await showDialog<Map<String, double>>(
        context: context,
        builder: (context) => _BulkProductDialog(productName: product['name'], pricePerKg: price),
      );

      if (result != null) {
        // Recalculate based on input type
        if (result['type'] == 1) { // By Price (Amount)
           // If user enters $50 pesos, quantity is 50 / pricePerKg
           double amount = result['value']!;
           quantity = amount / price;
        } else { // By Weight
           quantity = result['value']!;
        }
      } else {
        return; // Cancelled
      }
    }

    setState(() {
      final existingIndex = currentTicket.items.indexWhere((item) => item.name == product['name']);
      if (existingIndex != -1) {
        currentTicket.items[existingIndex].quantity += quantity;
      } else {
        currentTicket.items.add(CartItem(
          name: product['name'],
          price: price,
          quantity: quantity,
          isBulk: isBulk,
        ));
      }
      _calculateTotals();
    });
  }

  void _calculateTotals() {
    currentTicket.subtotal = currentTicket.items.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
    currentTicket.total = currentTicket.subtotal - currentTicket.discount;
    if (currentTicket.total < 0) currentTicket.total = 0.0;
  }

  void _processPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Procesando pago del Ticket... \$${currentTicket.total.toStringAsFixed(2)}'),
        backgroundColor: const Color(0xFF05e265),
      ),
    );
  }

  Future<void> _showWithdrawalDialog() async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text('Salida de Efectivo', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monto a retirar',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.poppins(color: Colors.white),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              ),
            ),
            const SizedBox(height: 16),
             TextField(
              controller: reasonController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Motivo / Concepto',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Retiro registrado correctamente'), backgroundColor: Colors.orange),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
            child: Text('Registrar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class CartItem {
  String name;
  double price;
  double quantity;
  bool isBulk;

  CartItem({
    required this.name,
    required this.price,
    required this.quantity,
    this.isBulk = false,
  });
}

class _ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final bool isBulk;
  final VoidCallback onTap;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.isBulk,
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
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name
              Text(
                name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              
              // Price and Bulk Indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '\$${price.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF05e265),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isBulk) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Granel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemWidget({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Determine quantity display format
    String quantityText = item.isBulk 
        ? '${item.quantity.toStringAsFixed(3)} kg'
        : item.quantity.toInt().toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Row(
        children: [
          // Product Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  item.isBulk 
                      ? '\$${item.price.toStringAsFixed(2)} / kg'
                      : '\$${item.price.toStringAsFixed(2)} c/u',
                  style: GoogleFonts.poppins(color: Colors.white54, fontSize: 10),
                ),
              ],
            ),
          ),
          
          // Quantity Controls
          Row(
            children: [
              _QtyBtn(icon: Icons.remove, onTap: () => onQuantityChanged(item.quantity - (item.isBulk ? 0.1 : 1))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  quantityText,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              _QtyBtn(icon: Icons.add, onTap: () => onQuantityChanged(item.quantity + (item.isBulk ? 0.1 : 1))),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Item Total
          SizedBox(
            width: 70,
            child: Text(
              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: const Color(0xFF05e265),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
           IconButton(
            icon: Icon(Icons.close, color: Colors.red.withAlpha(150), size: 16),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
           ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _BulkProductDialog extends StatefulWidget {
  final String productName;
  final double pricePerKg;

  const _BulkProductDialog({required this.productName, required this.pricePerKg});

  @override
  State<_BulkProductDialog> createState() => _BulkProductDialogState();
}

class _BulkProductDialogState extends State<_BulkProductDialog> {
  int _inputType = 0; // 0 = Weight (kg), 1 = Price ($)
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a1a),
      title: Text(widget.productName, style: GoogleFonts.poppins(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _TypeButton(
                  label: 'Por Peso (kg)', 
                  isSelected: _inputType == 0, 
                  onTap: () => setState(() => _inputType = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TypeButton(
                  label: 'Por Monto (\$)', 
                  isSelected: _inputType == 1, 
                  onTap: () => setState(() => _inputType = 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 24),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: GoogleFonts.poppins(color: Colors.white30),
              prefixText: _inputType == 1 ? '\$ ' : '',
              suffixText: _inputType == 0 ? ' kg' : '',
              prefixStyle: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 24),
              suffixStyle: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF05e265))),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF05e265), width: 2)),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 8),
          Text(
            widget.pricePerKg.toStringAsFixed(2) + ' /kg',
            style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            double? value = double.tryParse(_controller.text);
            if (value != null && value > 0) {
              Navigator.pop(context, {'type': _inputType.toDouble(), 'value': value});
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
          child: Text('Agregar', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF05e265) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF05e265) : Colors.white24),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
