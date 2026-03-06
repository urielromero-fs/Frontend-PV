import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/product_filters.dart';
import '../services/sale_service.dart';
import '../services/inventory_service.dart';
import '../services/cashSession_service.dart';
import 'home_screen.dart';
import '../services/withdrawal_service.dart';

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
  double? amountTendered;
  String paymentMethod;
  DateTime createdAt;

  Ticket({
    required this.id,
    List<CartItem>? items,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.amountTendered,
    this.paymentMethod = 'Efectivo',
    DateTime? createdAt,
  }) : items = items ?? [],
       createdAt = createdAt ?? DateTime.now();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Ticket> _tickets = [];

  final TextEditingController searchController = TextEditingController();

  //Filtro
  String searchQuery = '';
  String selectedCategoryFilter = 'Todas';
  String selectedSortOption = 'Ninguno';
  bool filterBulkOnly = false;


  StateSetter? _currentModalSetState;

  final List<String> categoryFilters = [
    'Todas',
    "Sin categoría",
    "Abarrotes",
    "Básicos",
    "Botanas",
    "Enlatados",
    "Lácteos",
    "Bebidas",
    "Carnes",
    "Panadería",
    "Frutas y Verduras",
    "Limpieza",
    "Higiene Personal",
    "Artículos para Bebé",
    "Mascotas",
    "General",
    "Otros",
  ];

  final List<String> sortOptions = [
    'Ninguno',
    'Precio Ascendente',
    'Precio Descendente',
  ];

  //Cash session
  bool _isRegisterOpen = false;
  double _initialCash = 0.0;
  double _totalSales = 0.0;
  double _totalWithdrawals = 0.0;
  bool _isLoadingSession = false;
  String? _currentSessionId;
  

  @override
  void initState() {
    super.initState();
    _addNewTicket();
    _initCashSession();
  }

  Future<void> _initCashSession() async {
    await _checkOpenSession();

    // Solo mostrar diálogo si no hay sesión abierta
    if (!_isRegisterOpen) {
      _showOpenRegisterDialog();
    }
  }

  Future<void> _checkOpenSession() async {
    final result = await CashSessionService.getOpenSession();



            if (!result['success']) {            
              return;
            }

            final data = result['data'];

            if (data == null) {
              setState(() {
                _isRegisterOpen = false;
                _currentSessionId = null;
              });
              return;
            }

            // 
            if (data is Map<String, dynamic>) {
              setState(() {
                _isRegisterOpen = true;
                _currentSessionId = data['_id'];
                _initialCash = (data['openingAmount'] ?? 0).toDouble();
              });
            }
          }

  Future<void> _processSale() async {
    //Mostrar diálogo de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF05e265)),
      ),
    );

    try {
      // Mapear items al formato del endpoint

      final List<Map<String, dynamic>> productsPayload = currentTicket.items
          .map((item) {
            return {
              'productId': item.id.toString(),
              'quantity': item.quantity.toDouble(),
            };
          })
          .toList();

      

      //Llamar al servicio
      final result = await SaleService.createSale(
          products: productsPayload,
          paymentMethod: currentTicket.paymentMethod,
          discount: currentTicket.discount
          
      );

      // Quitar diálogo de carga
      Navigator.pop(context);



    if (result['success']) {
      // Actualizar contadores locales para el reporte diario

        //Actualizar inventario 
        await Provider.of<ProductProvider>(context, listen: false)
            .fetchProducts();
      

        setState(() {
          _totalSales += currentTicket.total;
          currentTicket.items.clear();
          currentTicket.amountTendered = null;
          currentTicket.discount = 0.0;
          currentTicket.paymentMethod = 'Efectivo';
          _calculateTotals();
        });

        _showSuccessDialog(result['message']);
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Quitar carga en caso de error
      _showErrorSnackBar('Error de conexión: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(message)),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFF05e265),
          size: 60,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Aceptar',
              style: TextStyle(color: Color(0xFF05e265)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOpenRegisterDialog() async {
    final amountController = TextEditingController();
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Iniciar Cobro de Caja',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cantidad para iniciar el cobro de caja:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monto inicial',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.poppins(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
               Navigator.pop(context);
               Navigator.pop(context); 
            },
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text) ?? 0.0;

              setState(() => _isLoadingSession = true);

              final result = await CashSessionService.startSession(amount);

              setState(() => _isLoadingSession = false);

              if (result['success']) {
                final data = result['data'];

                setState(() {
                  _initialCash = amount;
                  _isRegisterOpen = true;
                  _currentSessionId = data?['_id'];
                });

                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(result['message'])));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
            ),
            child: Text(
              'Iniciar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCloseRegisterDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Cerrar Operación',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas cerrar la caja?',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: //() {
                //   setState(() {
                //     _isRegisterOpen = false;
                //   });
                //   Navigator.pop(context); // Close the confirmation dialog
                //   _showDailyReportDialog(); // Open the report dialog
                // },
                () async {
                  if (_currentSessionId == null) return;

                  setState(() => _isLoadingSession = true);

                 

                  final result = await CashSessionService.closeSession(
                    _currentSessionId.toString()                    
                  );

                  

                  setState(() => _isLoadingSession = false);

                  if (result['success']) {
                    setState(() {
                      _isRegisterOpen = false;
                      _currentSessionId = null;
                    });

                    Navigator.pop(context);

                    await _showDailyReportDialog();

                       
                      
                      
                    //Redirigir al dashboard
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false, // elimina todas las rutas anteriores
                    );
                  } else {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(result['message'])));
                  }
                },

            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Cerrar Caja',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDailyReportDialog() async {
    final double endCash = _initialCash + _totalSales - _totalWithdrawals;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Reporte del Día',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportRow(
              'Fondo Inicial:',
              '\$${_initialCash.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _buildReportRow(
              'Total Vendido:',
              '\$${_totalSales.toStringAsFixed(2)}',
              color: const Color(0xFF05e265),
            ),
            const SizedBox(height: 8),
            _buildReportRow(
              'Salidas de Efectivo:',
              '-\$${_totalWithdrawals.toStringAsFixed(2)}',
              color: Colors.redAccent,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Colors.white24),
            ),
            _buildReportRow(
              'Total en Caja:',
              '\$${endCash.toStringAsFixed(2)}',
              isBold: true,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _initialCash = 0.0;
                _totalSales = 0.0;
                _totalWithdrawals = 0.0;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
            ),
            child: Text(
              'Aceptar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(
    String label,
    String value, {
    Color color = Colors.white,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white70,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
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
    final provider = Provider.of<ProductProvider>(context);
    final allProducts = provider.allProducts;

    final filteredProducts = filterProducts(
      products: provider.allProducts,
      searchQuery: searchQuery,
      category: selectedCategoryFilter,
      onlyBulk: filterBulkOnly,
      sortOption: selectedSortOption,
    );

    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return KeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f12) {
          if (currentTicket.items.isNotEmpty) {
            if (currentTicket.amountTendered == null) {
              _showPaymentDialog();
            } else {
              _processSale();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            Text(
              'Cobros',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            if (_isRegisterOpen) ...[
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF05e265).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF05e265).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  'Caja Abierta',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF05e265),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
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
          if (_isRegisterOpen)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 4.0 : 8.0),
              child: ElevatedButton.icon(
                onPressed: _showCloseRegisterDialog,
                icon: const Icon(Icons.lock_outline, size: 16),
                label: isMobile
                    ? const Text('')
                    : const Text('Cerrar Operación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  foregroundColor: Colors.orange,
                  elevation: 0,
                  side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                  padding: isMobile ? const EdgeInsets.all(8) : null,
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
            child: ElevatedButton.icon(
              onPressed: _showWithdrawalDialog,
              icon: const Icon(Icons.money_off, size: 16),
              label: isMobile
                  ? const Text('')
                  : const Text('Salida de Efectivo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                padding: isMobile ? const EdgeInsets.all(8) : null,
              ),
            ),
          ),
        ],
      ),
      body: isMobile
          ? _buildMobileLayout(filteredProducts)
          : Row(children: _buildDesktopLayout(filteredProducts)),
      floatingActionButton: isMobile ? _buildMobileCartBottomBar() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    ),
  );
}

  Widget _buildMobileLayout(List<dynamic> filteredProducts) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFF000000), const Color(0xFF1a1a1a)],
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
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      onSubmitted: (value) => _onSearchSubmitted(value),
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
                  onPressed: _showFilterDialog,

                  icon: const Icon(Icons.filter_list, color: Colors.white70),
                  tooltip: 'Filtrar',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Products Grid
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 80),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return _ProductListTile(
                    name: product['name'],
                    price: (product['sellingPrice'] as num?)?.toDouble() ?? 0.0,
                    isBulk: product['isBulk'] ?? false,
                    units: (product['units'] as num?)?.toDouble() ?? 0.0,
                    remainingUnits: ((product['units'] as num?)?.toDouble() ?? 0.0) - 
                        (currentTicket.items.where((it) => it.name == product['name']).fold(0.0, (sum, it) => sum + it.quantity)),
                    onTap: () => _addToCart(product),
                    onAddStock: () => _showAddStockModal(product),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDesktopLayout(List<dynamic> filteredProducts) {
    return [
      // Left Panel - Product Search/Add
      Expanded(
        flex: 2,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF000000), const Color(0xFF1a1a1a)],
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
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                          onSubmitted: (value) => _onSearchSubmitted(value),
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.white70,
                            ),
                            icon: const Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter Buttons (Example)
                    IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(
                        Icons.filter_list,
                        color: Colors.white70,
                      ),
                      tooltip: 'Filtrar',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Products Grid
                Expanded(
                child: ListView.separated(
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _ProductListTile(
                      name: product['name'],
                      price:
                          (product['sellingPrice'] as num?)?.toDouble() ??
                          0.0,
                      isBulk: product['isBulk'] ?? false,
                      units: (product['units'] as num?)?.toDouble() ?? 0.0,
                      remainingUnits: ((product['units'] as num?)?.toDouble() ?? 0.0) - 
                          (currentTicket.items.where((it) => it.name == product['name']).fold(0.0, (sum, it) => sum + it.quantity)),
                      onTap: () => _addToCart(product),
                      onAddStock: () => _showAddStockModal(product),
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
      Container(width: 1, color: Colors.white.withAlpha(26)),

      // Right Panel - Tickets & Cart
      Expanded(
        flex: 3,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0xFF1a1a1a), const Color(0xFF000000)],
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
                          setState(
                            () {},
                          ); // Rebuild to show selected ticket content
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Color(0xFF05e265),
                      ),
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
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                currentTicket.items.clear();
                                currentTicket.discount = 0.0;
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

                                            final item = currentTicket.items[index];

                                            if (quantity > item.units) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('No hay suficiente stock disponible'),
                                                ),
                                              );
                                              return;
                                            }

                                            if (quantity <= 0) {
                                              setState(() {
                                                currentTicket.items.removeAt(index);
                                                _calculateTotals();
                                              });
                                              return;
                                            }

                                            setState(() {
                                              item.quantity = quantity;

                                              final wholesaleMin = item.wholesaleMinUnits ?? 0;
                                              final wholesalePrice = item.wholesalePrice ?? 0;
                                              final normalPrice = item.originalPrice ?? item.price;

                                              if (wholesaleMin > 0 && quantity >= wholesaleMin) {
                                                item.price = wholesalePrice;
                                              } else {
                                                item.price = normalPrice;
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
                            if (currentTicket.discount > 0) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                
                                  Text(
                                    '\$${currentTicket.subtotal.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Descuento',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '-\$${currentTicket.discount.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _showDiscountDialog(),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: Colors.white24),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (currentTicket.discount == 0) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _showDiscountDialog(),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.withOpacity(
                                                0.5,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.local_offer_outlined,
                                                color: Colors.orange,
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Desc.',
                                                style: GoogleFonts.poppins(
                                                  color: Colors.orange,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '\$${currentTicket.total.toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF05e265),
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (currentTicket.amountTendered != null) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recibido:',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '\$${currentTicket.amountTendered!.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Cambio:',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  Text(
                                    '\$${(currentTicket.amountTendered! - currentTicket.total).toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: currentTicket.items.isEmpty
                                    ? null
                                    : () {
                                        if (currentTicket.amountTendered ==
                                            null) {
                                          _showPaymentDialog();
                                        } else {
                                          _processSale();
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF05e265),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  currentTicket.amountTendered == null
                                      ? 'COBRAR'
                                      : 'FINALIZAR VENTA',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
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
    ];
  }

  Widget _buildMobileCartBottomBar() {
    int totalItems = currentTicket.items.fold(
      0,
      (sum, item) => sum + item.quantity.toInt(),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF05e265),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05e265).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showMobileCartBottomSheet,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, color: Colors.white),
                if (totalItems > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        totalItems.toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Text(
              'Ver Carrito',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '\$${currentTicket.total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMobileCartBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
             _currentModalSetState = setModalState;
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: const BoxDecoration(
                color: Color(0xFF1a1a1a),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
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
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white70,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
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
                                                padding: const EdgeInsets.only(
                                                  left: 8.0,
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    _closeTicket(entry.key);
                                                    setModalState(() {});
                                                    setState(() {});
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                    onTap: (index) {
                                      setModalState(() {});
                                      setState(() {});
                                    },
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Color(0xFF05e265),
                                  ),
                                  onPressed: () {
                                    _addNewTicket();
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                  tooltip: 'Nuevo Ticket',
                                ),
                              ],
                            ),
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

                                                final item = currentTicket.items[index];

                                                if (quantity > item.units) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('No hay suficiente stock disponible'),
                                                    ),
                                                  );
                                                  return;
                                                }

                                                if (quantity <= 0) {
                                                    setModalState(() {
                                                      currentTicket.items.removeAt(index);
                                                      _calculateTotals();
                                                    });
                                                    setState(() {}); 
                                                    return;
                                                }

                                                // final wholesaleMin = item.wholesaleMinUnits ?? 0;
                                                //       final wholesalePrice = item.wholesalePrice ?? 0;
                                                //       final normalPrice = item.originalPrice ?? item.price;

                                                // if(quantity >= wholesaleMin && wholesaleMin > 0) {
                                                //   item.price = wholesalePrice;
                                                //   setModalState(() {
                                                //       item.quantity = quantity;
                                                //       _calculateTotals();
                                                //     });
                                                  
                                                // } else {
                                                //   item.price = normalPrice;
                                                //   setModalState(() {
                                                //       item.quantity = quantity;
                                                //       _calculateTotals();
                                                //     });
                                                // }


                                                setModalState(() {

                                                      // item.quantity = quantity;

                                                      // final wholesaleMin = item.wholesaleMinUnits ?? 0;
                                                      // final wholesalePrice = item.wholesalePrice ?? 0;
                                                      // final normalPrice = item.originalPrice ?? item.price;
                                                      

                                                      // if (wholesaleMin > 0 && quantity >= wholesaleMin) {
                                                      //   item.price = wholesalePrice;
                                                      // } else {
                                                      //   item.price = normalPrice;
                                                      // }


                                                      item.quantity = quantity;

                                                      final wholesaleMin = item.wholesaleMinUnits ?? 0;
                                                      final wholesalePrice = item.wholesalePrice ?? 0;
                                                      final normalPrice = item.originalPrice ?? item.price;

                                                      if (wholesaleMin > 0 && quantity >= wholesaleMin) {
                                                        item.price = wholesalePrice;
                                                      } else {
                                                        item.price = normalPrice;
                                                      }



                                             



                                                      _calculateTotals();



                                                });

                                                setState(() {
                                                   
                                                }); 
                                              }, 



                                          onRemove: () {
                                            setModalState(() {
                                              currentTicket.items.removeAt(index);
                                              _calculateTotals();
                                            });
                                            setState(() {});
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
                              border: Border.all(
                                color: Colors.white.withAlpha(26),
                              ),
                            ),
                            child: Column(
                              children: [
                                if (currentTicket.discount > 0) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Subtotal',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        '\$${currentTicket.subtotal.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Descuento',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            '-\$${currentTicket.discount.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              color: Colors.orange,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _showDiscountDialog(
                                              setModalState: setModalState,
                                            ),
                                            child: const Icon(
                                              Icons.edit,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Divider(color: Colors.white24),
                                  const SizedBox(height: 8),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Total',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (currentTicket.discount == 0) ...[
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => _showDiscountDialog(
                                              setModalState: setModalState,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange
                                                    .withOpacity(0.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.orange
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.local_offer_outlined,
                                                    color: Colors.orange,
                                                    size: 12,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Desc.',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.orange,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '\$${currentTicket.total.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(
                                        color: const Color(0xFF05e265),
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                if (currentTicket.amountTendered != null) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Recibido:',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        '\$${currentTicket.amountTendered!.toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Cambio:',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                        ),
                                      ),
                                      Text(
                                        '\$${(currentTicket.amountTendered! - currentTicket.total).toStringAsFixed(2)}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: currentTicket.items.isEmpty
                                        ? null
                                        : () {
                                            if (currentTicket.amountTendered ==
                                                null) {
                                              _showPaymentDialog(
                                                setModalState: setModalState,
                                              );
                                            } else {
                                              _processSale();
                                              Navigator.pop(context);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF05e265),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      currentTicket.amountTendered == null
                                          ? 'COBRAR'
                                          : 'FINALIZAR VENTA',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                      ),
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
            );
          },
        );
      },
    );
  }











  Future<void> _showAddStockModal(Map product) async {
    final TextEditingController stockController = TextEditingController();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: Text(
              'Agregar Stock',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Producto: ${product['name']}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF05e265),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Stock actual: ${product['units']} ${product['isBulk'] == true ? 'Kg CT' : 'Unidades'}',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: stockController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Cantidad a agregar',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final String val = stockController.text.trim();
                        if (val.isEmpty) return;

                        final double addUnits = double.tryParse(val) ?? 0;
                        if (addUnits <= 0) return;

                        setModalState(() => isSaving = true);

                        final double currentUnits =
                            double.tryParse(product['units']?.toString() ?? '0') ??
                            0;
                        final double newUnits = currentUnits + addUnits;

                        final result = await InventoryService.updateProduct(
                          id: product['_id'],
                          name: product['name'],
                          barcode: product['barcode'] ?? 'N/A',
                          isBulk: product['isBulk'] ?? false,
                          weight: (product['weight'] ?? 0.0).toDouble(),
                          category: product['category'] ?? 'Sin categoría',
                          units: product['isBulk'] == true ? newUnits.toInt() : newUnits.toInt(), // API expects int for units often, but let's send what it needs
                          buyingPrice:
                              (product['buyingPrice'] ?? 0.0).toDouble(),
                          sellingPrice:
                              (product['sellingPrice'] ?? 0.0).toDouble(),
                          bulkPrice: (product['bulkPrice'] ?? 0.0).toDouble(),
                          hasWholesalePrice:
                              product['hasWholesalePrice'] ?? false,
                          wholesalePrice:
                              (product['wholesalePrice'] ?? 0.0).toDouble(),
                          wholesaleMinUnits:
                              (product['wholesaleMinUnits'] ?? 0) as int,
                        );

                        if (result['success'] == true) {
                          if (mounted) {
                            await Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            ).fetchProducts();
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock actualizado correctamente'),
                                backgroundColor: Color(0xFF05e265),
                              ),
                            );
                          }
                        } else {
                          if (mounted) {
                            setModalState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result['message'] ?? 'Error al actualizar',
                                ),
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05e265),
                  foregroundColor: Colors.black,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Agregar',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _addToCart(Map<String, dynamic> product) async {
    //double price = product['price'];

    final wholesaleMin = (product['wholesaleMinUnits'] as num?)?.toDouble() ?? 0;
    final wholesalePrice = (product['wholesalePrice'] as num?)?.toDouble() ?? 0;
    //final normalPrice = (product['sellingPrice'] as num?)?.toDouble() ?? 0;

    double price = (product['sellingPrice'] as num?)?.toDouble() ?? 0.0;
   // double price = normalPrice;
    double units = (product['units'] as num?)?.toDouble() ?? 0.0;
    double quantity = 1;
    bool isBulk = product['isBulk'] ?? false;

    if (isBulk) {
      final result = await showDialog<Map<String, double>>(
        context: context,
        builder: (context) =>
            _BulkProductDialog(productName: product['name'], pricePerKg: price),
      );

      if (result != null) {
        // Recalculate based on input type
        if (result['type'] == 1) {
          // By Price (Amount)
          // If user enters $50 pesos, quantity is 50 / pricePerKg
          double amount = result['value']!;
          quantity = amount / price;
        } else {
          // By Weight
          quantity = result['value']!;
        }
      } else {
        return; // Cancelled
      }
    }

    setState(() {
      final existingIndex = currentTicket.items.indexWhere((item) => item.name == product['name']);

      double alreadyInCart = 0;

      if (existingIndex != -1) {
         alreadyInCart = currentTicket.items[existingIndex].quantity;
      }
      
      if (alreadyInCart + quantity > units) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock insuficiente.',
            ),
          ),
        );
        return;
      }

      if (existingIndex != -1) {

        final item = currentTicket.items[existingIndex];
        item.quantity += quantity;

        if(wholesaleMin > 0 && item.quantity >= wholesaleMin) {
          item.price = wholesalePrice;
        } else {
          item.price = price;
        }


      }else {


        // double initialPrice = quantity >= wholesaleMin && wholesaleMin > 0
        //     ? wholesalePrice
        //     : normalPrice;


        currentTicket.items.add(CartItem(
          id: product['_id'],
          name: product['name'],
          //price: price,
          price: price,
          quantity: quantity,
          isBulk: isBulk,
          units: units , 
          originalPrice: price, 
          wholesalePrice: wholesalePrice, 
          wholesaleMinUnits: wholesaleMin, 

        ));
      }
      _calculateTotals();
    });


        
      // if (_currentModalSetState != null) {
      //   _currentModalSetState!(() {}); // reconstruye el modal
      // }

      
     
  }

  void _calculateTotals() {
    currentTicket.subtotal = currentTicket.items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    currentTicket.total = currentTicket.subtotal - currentTicket.discount;
    if (currentTicket.total < 0) currentTicket.total = 0.0;

    if (currentTicket.amountTendered != null &&
        currentTicket.amountTendered! < currentTicket.total) {
      currentTicket.amountTendered = null;
    }
  }

  Future<void> _showPaymentDialog({StateSetter? setModalState}) async {
    final amountController = TextEditingController();
    String localPaymentMethod = currentTicket.paymentMethod;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: Text(
              'Cobrar - \$${currentTicket.total.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Método de Pago:',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPaymentMethodOption(
                      icon: Icons.money,
                      label: 'Efectivo',
                      isActive: localPaymentMethod == 'Efectivo',
                      onTap: () {
                        setDialogState(() => localPaymentMethod = 'Efectivo');
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPaymentMethodOption(
                      icon: Icons.credit_card,
                      label: 'Tarjeta',
                      isActive: localPaymentMethod == 'Tarjeta',
                      onTap: () {
                        setDialogState(() => localPaymentMethod = 'Tarjeta');
                      },
                    ),
                    const SizedBox(width: 12),
                    _buildPaymentMethodOption(
                      icon: Icons.account_balance,
                      label: 'Transferencia',
                      isActive: localPaymentMethod == 'Transferencia',
                      onTap: () {
                        setDialogState(() => localPaymentMethod = 'Transferencia');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Cantidad con la que paga el cliente:',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Monto recibido',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    prefixText: '\$ ',
                    prefixStyle: GoogleFonts.poppins(color: Colors.white),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                  ),
                  onSubmitted: (_) {
                    final double amount = double.tryParse(amountController.text) ?? 0.0;
                    if (amount >= currentTicket.total) {
                      if (setModalState != null) {
                        setModalState(() {
                          currentTicket.amountTendered = amount;
                          currentTicket.paymentMethod = localPaymentMethod;
                        });
                      }
                      setState(() {
                        currentTicket.amountTendered = amount;
                        currentTicket.paymentMethod = localPaymentMethod;
                      });
                      Navigator.pop(context);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final double amount =
                      double.tryParse(amountController.text) ?? 0.0;
                  if (amount >= currentTicket.total) {
                    if (setModalState != null) {
                      setModalState(() {
                        currentTicket.amountTendered = amount;
                        currentTicket.paymentMethod = localPaymentMethod;
                      });
                    }
                    setState(() {
                      currentTicket.amountTendered = amount;
                      currentTicket.paymentMethod = localPaymentMethod;
                    });
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'El monto recibido debe ser mayor o igual al total',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05e265),
                ),
                child: Text(
                  'Aceptar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 100, // Increased from 85 to 100
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF05e265).withOpacity(0.2) : Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF05e265) : Colors.white.withAlpha(26),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF05e265) : Colors.white70,
              size: 28, // Increased from 24
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchSubmitted(String value) {
    if (value.isEmpty) return;

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = provider.allProducts;

    // Buscar coincidencia exacta por código de barras primero
    final product = allProducts.firstWhere(
      (p) => p['barcode']?.toString() == value,
      orElse: () => null,
    );

    if (product != null) {
      _addToCart(product);
      // Limpiar búsqueda
      searchController.clear();
      setState(() {
        searchQuery = '';
      });
    }
  }

  void _processPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Procesando pago del Ticket... \$${currentTicket.total.toStringAsFixed(2)}',
        ),
        backgroundColor: const Color(0xFF05e265),
      ),
    );

    setState(() {
      _totalSales += currentTicket.total;
      currentTicket.items.clear();
      currentTicket.amountTendered = null;
      currentTicket.discount = 0.0;
      _calculateTotals();
    });
  }

  Future<void> _showDiscountDialog({StateSetter? setModalState}) async {
    final discountController = TextEditingController(
      text: currentTicket.discount > 0
          ? currentTicket.discount.toStringAsFixed(2)
          : '',
    );
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Aplicar Descuento',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el monto de descuento para este ticket:',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monto de descuento',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.poppins(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          if (currentTicket.discount > 0)
            TextButton(
              onPressed: () {
                if (setModalState != null) {
                  setModalState(() {
                    currentTicket.discount = 0.0;
                    _calculateTotals();
                  });
                }
                setState(() {
                  currentTicket.discount = 0.0;
                  _calculateTotals();
                });
                Navigator.pop(context);
              },
              child: Text(
                'Quitar Descuento',
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final double discount =
                  double.tryParse(discountController.text) ?? 0.0;
              if (discount >= 0) {
                if (setModalState != null) {
                  setModalState(() {
                    currentTicket.discount = discount;
                    _calculateTotals();
                  });
                }
                setState(() {
                  currentTicket.discount = discount;
                  _calculateTotals();
                });
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
            ),
            child: Text(
              'Aplicar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
        title: Text(
          'Salida de Efectivo',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d+\.?\d{0,2}'),
                ),
              ],
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Monto a retirar',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                prefixText: '\$ ',
                prefixStyle: GoogleFonts.poppins(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Motivo / Concepto',
                labelStyle: GoogleFonts.poppins(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(color: Colors.white54),
            ),
          ),
          ElevatedButton(

            // onPressed: () {
            //   final double amount =
            //       double.tryParse(amountController.text) ?? 0.0;
            //   setState(() {
            //     _totalWithdrawals += amount;
            //   });
            //   Navigator.pop(context);
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(
            //       content: Text('Retiro registrado correctamente'),
            //       backgroundColor: Colors.orange,
            //     ),
            //   );
            // },

            onPressed: () async {
                  final double amount =
                      double.tryParse(amountController.text) ?? 0.0;
                  final String reason = reasonController.text.trim();

                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa un monto válido'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingresa un motivo'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Mostrar loader mientras se hace la petición
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final response = await WithdrawalService.createWithdrawal(
                    amount: amount,
                    reason: reason,
                  );

                  Navigator.pop(context); // cerrar loader

                  if (response['success'] == true) {
                    setState(() {
                      _totalWithdrawals += amount;
                    });

                    Navigator.pop(context); // cerrar dialog principal

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Retiro registrado correctamente'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(response['message'] ?? 'Error inesperado'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },


            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
            ),
            child: Text(
              'Registrar',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: Text(
            'Filtros',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Categoría
                  DropdownButtonFormField<String>(
                    value: selectedCategoryFilter,
                    dropdownColor: const Color(0xFF1a1a1a),
                    items: categoryFilters.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedCategoryFilter = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Categoría'),
                  ),

                  const SizedBox(height: 16),

                  // Ordenamiento
                  DropdownButtonFormField<String>(
                    value: selectedSortOption,
                    dropdownColor: const Color(0xFF1a1a1a),
                    items: sortOptions.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedSortOption = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Ordenar por'),
                  ),

                  const SizedBox(height: 16),

                  // Granel
                  Row(
                    children: [
                      Checkbox(
                        value: filterBulkOnly,
                        activeColor: const Color(0xFF05e265),
                        onChanged: (value) {
                          setModalState(() {
                            filterBulkOnly = value ?? false;
                          });
                        },
                      ),
                      Text(
                        'Solo productos a granel',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  selectedCategoryFilter = 'Todas';
                  selectedSortOption = 'Ninguno';
                  filterBulkOnly = false;
                });
                //applyFilters();
                Navigator.pop(context);
              },
              child: const Text('Limpiar'),
            ),
            ElevatedButton(
              onPressed: () {
                //applyFilters();
                setState(() {}); // aplica filtros
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
              ),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }
}

class CartItem {
  String id;
  String name;
  double price;
  double quantity;
  bool isBulk;
  double units; 

  double? wholesaleMinUnits;
  double? wholesalePrice;
  double? originalPrice;
  

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.units,
    this.isBulk = false,
    this.wholesaleMinUnits,
    this.wholesalePrice,
    this.originalPrice,
  });

  


}

class _ProductListTile extends StatelessWidget {
  final String name;
  final double price;
  final bool isBulk;
  final double units;
  final double remainingUnits;
  final VoidCallback onTap;
  final VoidCallback onAddStock;

  const _ProductListTile({
    required this.name,
    required this.price,
    required this.isBulk,
    required this.units,
    required this.remainingUnits,
    required this.onTap,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStock = remainingUnits > 0;

    return GestureDetector(
      onTap: hasStock ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(hasStock ? 13 : 8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasStock 
                ? Colors.white.withAlpha(26) 
                : Colors.red.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            // Icon / Indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (hasStock ? const Color(0xFF05e265) : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBulk ? Icons.scale : Icons.inventory_2,
                color: hasStock ? const Color(0xFF05e265) : Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            
            // Product Info
            Expanded(
              child: Opacity(
                opacity: hasStock ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          '\$${price.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF05e265),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isBulk) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: Text(
                              'Granel',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
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

            // Stock Status / Add Stock Button
            if (!hasStock) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SIN STOCK',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAddStock,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05e265).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF05e265).withAlpha(100)),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF05e265),
                    size: 18,
                  ),
                ),
              ),
            ] else 
              Icon(
                Icons.add_circle_outline,
                color: Colors.white.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}

class _CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;

  // const _CartItemWidget({
  //   required this.item,
  //   required this.onQuantityChanged,
  //   required this.onRemove,
  // });

  const _CartItemWidget({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    // Determine quantity display format
    String quantityText = item.isBulk
        ? '${item.quantity.toStringAsFixed(3)} KG'
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
                  style: GoogleFonts.poppins(
                    color: Colors.white54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Quantity Controls
          Row(
            children: [
              _QtyBtn(
                icon: Icons.remove,
                onTap: () =>
                    onQuantityChanged(item.quantity - (item.isBulk ? 0.1 : 1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  quantityText,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
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

  const _BulkProductDialog({
    required this.productName,
    required this.pricePerKg,
  });

  @override
  State<_BulkProductDialog> createState() => _BulkProductDialogState();
}

class _BulkProductDialogState extends State<_BulkProductDialog> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightChanged);
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _amountController.removeListener(_onAmountChanged);
    _weightController.dispose();
    _amountController.dispose();
    _weightFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onWeightChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final text = _weightController.text;
    if (text.isEmpty) {
      _amountController.clear();
    } else {
      final val = double.tryParse(text) ?? 0.0;
      _amountController.text = (val * widget.pricePerKg).toStringAsFixed(2);
    }
    _isUpdating = false;
  }

  void _onAmountChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final text = _amountController.text;
    if (text.isEmpty) {
      _weightController.clear();
    } else {
      final val = double.tryParse(text) ?? 0.0;
      _weightController.text = (val / widget.pricePerKg).toStringAsFixed(3);
    }
    _isUpdating = false;
  }

  void _submit() {
    final qty = double.tryParse(_weightController.text);
    if (qty != null && qty >= 0) {
      Navigator.pop(context, {
        'type': 0.0,
        'value': qty,
      });
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_weightFocus.hasFocus) {
          _amountFocus.requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                 event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_amountFocus.hasFocus) {
          _weightFocus.requestFocus();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a1a),
      title: Text(
        widget.productName,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: Container(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                // Weight Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peso (Kg)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        focusNode: _weightFocus,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                        ],
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.000',
                          hintStyle: GoogleFonts.poppins(color: Colors.white12),
                          suffixText: 'Kg',
                          suffixStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF02e3b2), width: 1.5)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Icon in middle
                const Icon(Icons.sync, color: Colors.white24, size: 20),
                const SizedBox(width: 16),
                // Price/Amount Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto (\$)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        style: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 22, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.poppins(color: Colors.white12),
                          prefixText: '\$ ',
                          prefixStyle: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 18),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF05e265), width: 1.5)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Precio por Kg: \$${widget.pricePerKg.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF05e265),
          ),
          child: Text(
            'Agregar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF05e265) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF05e265) : Colors.white24,
          ),
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
