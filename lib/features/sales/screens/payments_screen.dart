import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pv26/features/inventory/providers/product_provider.dart';
import 'package:pv26/core/utils/product_filters.dart';
import '../services/sale_service.dart';
import 'package:pv26/features/inventory/services/inventory_service.dart';
import '../services/cash_session_service.dart';
import 'package:pv26/features/home/screens/home_screen.dart';
import '../services/withdrawal_service.dart';
import '../services/print_service.dart';
import '../models/sales_models.dart';
import 'package:pv26/features/sales/widgets/product_list_tile.dart';
import 'package:pv26/features/sales/widgets/cart_item_widget.dart';
import 'package:pv26/features/sales/widgets/bulk_product_dialog.dart';
import 'package:pv26/features/sales/widgets/withdrawal_dialog.dart';
import '../../inventory/widgets/add_stock_dialog.dart';
import 'package:pv26/core/utils/currency_formatter.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../users/services/users_service.dart'; 

String _f(double value) => CurrencyFormatter.format(value);
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});
  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}
class _PaymentsScreenState extends State<PaymentsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Ticket> _tickets = [];
  final TextEditingController searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime? _lastKeyPress;
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

  //Onboarding  
  final GlobalKey _aperturaCajaKey = GlobalKey(); 
  final GlobalKey _cerrarCajaKey = GlobalKey(); 
  final GlobalKey _historialKey = GlobalKey(); 
  final GlobalKey _salidaEfectivoKey = GlobalKey(); 
  final GlobalKey _agregaTicketKey = GlobalKey(); 
  final GlobalKey _cobrarKey = GlobalKey(); 
  final GlobalKey _discountKey = GlobalKey(); 


  Map<String, dynamic> _onboarding = {
      'isCompleted': false,
      'stepsCompleted': {
        'salesOpenCash': false,
        'salesPostCash': false,
      },
  };




  @override
  void initState() {

    super.initState();

     _addNewTicket();

    _initAllAsync();


  }


  
    Future<void> _initOnboarding() async {
      if (_onboarding['isCompleted'] == true) return;

      if(_onboarding['stepsCompleted']['salesOpenCash'] == true) return; 

      if(!_isRegisterOpen){
          WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(const Duration(milliseconds: 600), () {
           if (mounted) {
                ShowcaseView.get().startShowCase([_aperturaCajaKey]);
              }
          });
        });
      }


      await _markStepCompleted('salesOpenCash');
    }

 
  Future<void> _initAllAsync() async {
    await _initCashSession();   // espera a que la sesión de caja se inicialice
    await _loadOnboarding();    // carga los datos de onboarding desde SharedPreferences
    await _initOnboarding();    // decide si mostrar el Showcase
  }

  Future<void> _loadOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_onboarding');
      
      if (jsonStr != null) {
        setState(() {
          _onboarding = jsonDecode(jsonStr);
          
        });
    }
   }


  Future<void> _markStepCompleted(String step) async {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _onboarding['stepsCompleted'][step] = true;
      });

      await prefs.setString('user_onboarding', jsonEncode(_onboarding));

      final result = await UsersService.updateOnboardingStep(step: step);
      if (!result['success']) {
        print('Error al actualizar onboarding: ${result['message']}');
      }

  }


  void _startPostOpenShowcase() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 400), () {
          ShowcaseView.get().startShowCase([
            _cerrarCajaKey,
            _historialKey,
            _salidaEfectivoKey,
            _agregaTicketKey,
            _cobrarKey,
            _discountKey,
          ]);
        });
      });
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
    if (data is Map<String, dynamic>) {
      setState(() {
        _isRegisterOpen = true;
        _currentSessionId = data['_id'];
        _initialCash = (data['openingAmount'] ?? 0).toDouble();
      });
    }
  }

  Future<void> _processSale() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: const Color(0xFF05e265)),
      ),
    );

    try {
      final List<Map<String, dynamic>> productsPayload = currentTicket.items
          .map((item) {
            return {
              'productId': item.id.toString(),
              'quantity': item.quantity.toDouble(),
            };
          })
          .toList();

      final result = await SaleService.createSale(
        products: productsPayload,
        paymentMethod: currentTicket.paymentMethod,
        discount: currentTicket.discount,
      );

      Navigator.pop(context);

      if (result['success']) {
        await Provider.of<ProductProvider>(context, listen: false)
            .fetchProducts();

        final ticketItems = List<CartItem>.from(currentTicket.items);
        final ticketTotal = currentTicket.total;
        final ticketReceived = currentTicket.amountTendered ?? 0.0;
        final ticketChange = ticketReceived - ticketTotal;
        final ticketPaymentMethod = currentTicket.paymentMethod;

        setState(() {
          _totalSales += currentTicket.total;
          currentTicket.items.clear();
          currentTicket.amountTendered = null;
          currentTicket.discount = 0.0;
          currentTicket.paymentMethod = 'Efectivo';
          _calculateTotals();
        });

        _showSuccessDialog(
          result['message'],
          ticketData: {
            'items': ticketItems,
            'total': ticketTotal,
            'received': ticketReceived,
            'change': ticketChange,
            'paymentMethod': ticketPaymentMethod,
          },
        );
      } else {
        _showErrorSnackBar(result['message']);
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showErrorSnackBar('Error de conexión: $e');
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
  
  void _showSuccessDialog(String message, {Map<String, dynamic>? ticketData}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Icon(
          Icons.check_circle,
          color: Color(0xFF05e265),
          size: 60,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (ticketData != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildTicketDetailRow('Total:', _f(ticketData['total'])),
                    _buildTicketDetailRow('Recibido:', _f(ticketData['received'])),
                    _buildTicketDetailRow('Cambio:', _f(ticketData['change'])),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  PrintService.printTicket(
                    businessName: '',
                    items: ticketData['items'],
                    total: ticketData['total'],
                    received: ticketData['received'],
                    change: ticketData['change'],
                    paymentMethod: ticketData['paymentMethod'],
                  );
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text(
                  'Imprimir Ticket',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05e265),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Aceptar',
              style: GoogleFonts.poppins(
                color: const Color(0xFF05e265),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showOpenRegisterDialog() async {
    final amountController = TextEditingController();

      await  showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title:
              Text(
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

               //Open box field 
                  Showcase(
                          key: _aperturaCajaKey,
                          description: 'Agrega un monto para abrir la caja.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                                
                                TextField(
                                      controller: amountController,
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      inputFormatters: [CurrencyInputFormatter()],
                                      style: GoogleFonts.poppins(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Monto inicial',
                                        labelStyle: GoogleFonts.poppins(color: Colors.white70),
                                        prefixText: r'$ ',
                                        prefixStyle: GoogleFonts.poppins(color: Colors.white),
                                        enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                                        ),
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
              final amount = double.tryParse(amountController.text.replaceAll(",", "")) ?? 0.0;
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

                  if (_onboarding['stepsCompleted']['salesPostCash'] != true) {
                    _startPostOpenShowcase();   // Muestra los demás showcases
                    await _markStepCompleted('salesPostCash'); // Marca como completado
                  }

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
        backgroundColor: Theme.of(context).cardColor,
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
            onPressed:   () async {
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
        backgroundColor: Theme.of(context).cardColor,
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
              _f(_initialCash),
            ),
            const SizedBox(height: 8),
            _buildReportRow(
              'Total Vendido:',
              _f(_totalSales),
              color: const Color(0xFF05e265),
            ),
            const SizedBox(height: 8),
            _buildReportRow(
              'Salidas de Efectivo:',
              '-\$${NumberFormat("#,###.00").format(_totalWithdrawals)}',
              color: Colors.redAccent,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(color: Theme.of(context).dividerColor),
            ),
            _buildReportRow(
              'Total en Caja:',
              _f(endCash),
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
    searchController.dispose();
    _tabController.dispose();
    _searchFocusNode.dispose();
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
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.f12) {
            if (currentTicket.items.isNotEmpty) {
              if (currentTicket.amountTendered == null) {
                _showPaymentDialog().then((success) {
                  if (success == true) _processSale();
                });
              } else {
                _processSale();
              }
            }
          } else {
            // Lógica para capturar ráfagas rápidas de caracteres (Escáner de código de barras)
            final now = DateTime.now();
            if (_lastKeyPress != null && now.difference(_lastKeyPress!).inMilliseconds > 200) {
              _barcodeBuffer = ''; // Reiniciar si ha pasado mucho tiempo entre teclas (ej. escribiendo manual)
            }
            _lastKeyPress = now;
            
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              if (_barcodeBuffer.isNotEmpty) {
                final scannedCode = _barcodeBuffer;
                _barcodeBuffer = '';
                // Si el input de búsqueda ya está enfocado, él mismo manejará el 'enter'.
                // Evitamos agregarlo doble.
                if (!_searchFocusNode.hasFocus) {
                  _onSearchSubmitted(scannedCode);
                }
              }
            } else if (event.character != null) {
              _barcodeBuffer += event.character!;
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
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (_isRegisterOpen) ...[
              SizedBox(width: isMobile ? 8 : 16),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 8 : 12,
                  vertical: isMobile ? 8 : 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF05e265).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF05e265).withOpacity(0.5),
                  ),
                ),
                child: isMobile
                    ? const Icon(Icons.point_of_sale, color: Color(0xFF05e265), size: 16)
                    : Text(
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
        backgroundColor: Theme.of(context).cardColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_isRegisterOpen)
            Padding(
              padding: EdgeInsets.only(right: isMobile ? 4.0 : 8.0),
              child: isMobile
                  ? 
                  //Close session
                  Showcase(
                          key: _cerrarCajaKey,
                          description: 'Toca para cerrar la caja.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                               ElevatedButton(
                                  onPressed: _showCloseRegisterDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.withOpacity(0.2),
                                    foregroundColor: Colors.orange,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(36, 36),
                                  ),
                                  child: const Icon(Icons.lock_outline, size: 18),
                                )
                    
         
                        )   

                  : 
                  
                      Showcase(
                          key: _cerrarCajaKey,
                          description: 'Toca para cerrar la caja.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                                 ElevatedButton.icon(
                                  onPressed: _showCloseRegisterDialog,
                                  icon: const Icon(Icons.lock_outline, size: 16),
                                  label: const Text('Cerrar Operación'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.withOpacity(0.2),
                                    foregroundColor: Colors.orange,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.orange.withOpacity(0.5)),
                                  ),
                                ),
                    
         
                        )   

            ),
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 4.0 : 8.0),
            child: isMobile
                ? 
                
                //Historial button
                  Showcase(
                          key: _historialKey,
                          description: 'Toca para ver el historial de ventas.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [

                                  TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                              ElevatedButton(
                                  onPressed: _showSalesHistoryDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                    foregroundColor: Colors.blueAccent,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(36, 36),
                                  ),
                                  child: const Icon(Icons.history, size: 18),
                                )
                        ) 
 
                : 
                //Historial button
                  Showcase(
                          key: _historialKey,
                          description: 'Toca para ver el historial de ventas.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                              ElevatedButton.icon(
                                  onPressed: _showSalesHistoryDialog,
                                  icon: const Icon(Icons.history, size: 16),
                                  label: const Text('Historial'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.withOpacity(0.2),
                                    foregroundColor: Colors.blueAccent,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                  ),
                                ),
                        ) 

          ),
          Padding(
            padding: EdgeInsets.only(right: isMobile ? 8.0 : 16.0),
            child: isMobile
                ? 
                  //Withdrawal button
                  Showcase(
                          key: _salidaEfectivoKey,
                          description: 'Toca para hacer un retiro de efectivo.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                              ElevatedButton(
                                  onPressed: _showWithdrawalDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                    foregroundColor: Colors.redAccent,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(36, 36),
                                  ),
                                  child: const Icon(Icons.money_off, size: 18),
                                )
                        ) 

                
                

                : 
                 //Withdrawal button
                  Showcase(
                          key: _salidaEfectivoKey,
                          description: 'Toca para hacer un retiro de efectivo.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                              ElevatedButton.icon(
                                  onPressed: _showWithdrawalDialog,
                                  icon: const Icon(Icons.money_off, size: 16),
                                  label: const Text('Salida de efectivo'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.withOpacity(0.2),
                                    foregroundColor: Colors.redAccent,
                                    elevation: 0,
                                    side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                                  ),
                                ),
                        ) 

                

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
        color: Theme.of(context).scaffoldBackgroundColor,
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
                      focusNode: _searchFocusNode,
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      onSubmitted: (value) => _onSearchSubmitted(value),
                      decoration: InputDecoration(
                        hintText: 'Buscar producto...',
                        hintStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        icon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Category Filter Buttons (Example)
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  tooltip: 'Filtrar',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Products Grid
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: filteredProducts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductListTile(
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
            color: Theme.of(context).scaffoldBackgroundColor,
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
                          color: Theme.of(context).dividerColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                        ),
                        child: TextField(
                          focusNode: _searchFocusNode,
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
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            icon: Icon(
                              Icons.search,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            border: InputBorder.none,
                          ),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter Buttons (Example)
                    IconButton(
                      onPressed: _showFilterDialog,
                      icon: Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                    return ProductListTile(
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
            color: Theme.of(context).cardColor,
          ),
          child: Column(
            children: [
              // Ticket Tabs
              Container(
                color: Theme.of(context).cardColor,
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: const Color(0xFF05e265),
                        labelColor: const Color(0xFF05e265),
                        unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                                      child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.onSurface),
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

                 //add new ticket button
                  Showcase(
                          key: _agregaTicketKey,
                          description: 'Toca para agregar un nuevo ticket.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle,
                                  color: Color(0xFF05e265),
                                ),
                                onPressed: _addNewTicket,
                                tooltip: 'Nuevo Ticket',
                              ),
                        )



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
                            currentTicket.items.isEmpty
                                ? 'Carrito'
                                : 'Carrito (${currentTicket.items.fold<double>(0.0, (sum, item) => sum + (item.isBulk ? 1.0 : item.quantity)).toInt()} art.)',
                            style: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                      size: 48,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Ticket vacío',
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: currentTicket.items.length,
                                itemBuilder: (context, index) {
                                  return CartItemWidget(
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
                                    _f(currentTicket.subtotal),
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
                                        '-' + _f(currentTicket.discount),
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
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (currentTicket.discount == 0) ...[
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () => _showDiscountDialog(),
                                        child: 
                                        
                                        //Discount button
                                          Showcase(
                                                  key: _discountKey,
                                                  description: 'Toca para agregar un descuento.',
                                                  tooltipPadding: const EdgeInsets.all(12),
                                                  tooltipActions: [
                                                            TooltipActionButton(
                                                                  type: TooltipDefaultActionType.skip,
                                                                  backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                                  textStyle: TextStyle(color: Colors.white),
                                                                  name: 'Saltar',
                                                                
                                                                ), 
                                                            TooltipActionButton(
                                                              type: TooltipDefaultActionType.next,
                                                              backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                              textStyle: TextStyle(color: Colors.white),
                                                              name: 'Siguiente',
                                                            
                                                            )
                                                          ],
                                                  tooltipActionConfig: TooltipActionConfig(
                                                        alignment: MainAxisAlignment.center,
                                                      ),
                                                  child:  Container(
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
                                                        child: 
                                                                    Row(
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
                                                )

  
                                          

                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  _f(currentTicket.total),
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
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _f(currentTicket.amountTendered!),
                                      style: GoogleFonts.poppins(
                                        color: Theme.of(context).colorScheme.onSurface,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
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
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _f(currentTicket.amountTendered! - currentTicket.total),
                                      style: GoogleFonts.poppins(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: () {
                                      PrintService.printTicket(
                                        businessName: '',
                                        items: currentTicket.items,
                                        total: currentTicket.total,
                                        received: currentTicket.amountTendered!,
                                        change: currentTicket.amountTendered! - currentTicket.total,
                                        paymentMethod: currentTicket.paymentMethod,
                                      );
                                    },
                                    icon: Icon(Icons.print, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                    label: Text(
                                      'Imprimir previo',
                                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            SizedBox(
                              width: double.infinity,
                              child: 
                              
                              //Cobrar button 
                                  Showcase(
                                          key: _cobrarKey,
                                          description: 'Toca para cobrar los productos en el ticket.',
                                          tooltipPadding: const EdgeInsets.all(12),
                                          tooltipActions: [
                                                    TooltipActionButton(
                                                        type: TooltipDefaultActionType.skip,
                                                        backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                        textStyle: TextStyle(color: Colors.white),
                                                        name: 'Saltar',
                                                      
                                                      ), 
                                                    TooltipActionButton(
                                                      type: TooltipDefaultActionType.next,
                                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                      textStyle: TextStyle(color: Colors.white),
                                                      name: 'Siguiente',
                                                    
                                                    )
                                                  ],
                                          tooltipActionConfig: TooltipActionConfig(
                                                alignment: MainAxisAlignment.center,
                                              ),
                                          child:  
                                                ElevatedButton(
                                                  onPressed: currentTicket.items.isEmpty
                                                      ? null
                                                      : () {
                                                          if (currentTicket.amountTendered ==
                                                              null) {
                                                            _showPaymentDialog().then((success) {
                                                              if (success == true) _processSale();
                                                            });
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
                                                  child: 
                                                                                                Text(
                                                                  currentTicket.amountTendered == null
                                                                      ? 'COBRAR'
                                                                      : 'FINALIZAR VENTA',
                                                                  style: GoogleFonts.poppins(
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),
                                                  
                                                  
                                                  


                                                ),
                                        )

                              

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
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
              ],
            ),
            Text(
              _f(currentTicket.total),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
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
                                currentTicket.items.isEmpty 
                                    ? 'Carrito'
                                    : 'Carrito (${currentTicket.items.fold<double>(0.0, (sum, item) => sum + (item.isBulk ? 1.0 : item.quantity)).toInt()} art.)',
                                style: GoogleFonts.poppins(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: [
                                  if (currentTicket.items.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () {
                                        setModalState(() {
                                          currentTicket.items.clear();
                                          _calculateTotals();
                                        });
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                                      label: Text('Vaciar', style: GoogleFonts.poppins(color: Colors.redAccent)),
                                    ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Ticket Tabs
                          Container(
                            color: Theme.of(context).cardColor,
                            child: Row(
                              children: [
                                Expanded(
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: true,
                                    indicatorColor: const Color(0xFF05e265),
                                    labelColor: const Color(0xFF05e265),
                                    unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
                                                  child: Icon(
                                                    Icons.close,
                                                    size: 16,
                                                    color: Theme.of(context).colorScheme.onSurface,
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

                 //add new ticket button
                  Showcase(
                          key: _agregaTicketKey,
                          description: 'Toca para agregar un nuevo ticket.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.skip,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Saltar',
                                     
                                    ), 
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
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
                        )


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
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                            size: 48,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Ticket vacío',
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: currentTicket.items.length,
                                      itemBuilder: (context, index) {
                                        return CartItemWidget(
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
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _f(currentTicket.subtotal),
                                        style: GoogleFonts.poppins(
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                            '-\$${NumberFormat("#,###.00").format(currentTicket.discount)}',
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
                                  Divider(color: Theme.of(context).dividerColor),
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
                                            color: Theme.of(context).colorScheme.onSurface,
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
                                            child: 
                                          //Discount button
                                          Showcase(
                                                  key: _discountKey,
                                                  description: 'Toca para agregar un descuento.',
                                                  tooltipPadding: const EdgeInsets.all(12),
                                                  tooltipActions: [
                                                            TooltipActionButton(
                                                                type: TooltipDefaultActionType.skip,
                                                                backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                                textStyle: TextStyle(color: Colors.white),
                                                                name: 'Saltar',
                                                              
                                                              ), 
                                                            TooltipActionButton(
                                                              type: TooltipDefaultActionType.next,
                                                              backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                              textStyle: TextStyle(color: Colors.white),
                                                              name: 'Siguiente',
                                                            
                                                            )
                                                          ],
                                                  tooltipActionConfig: TooltipActionConfig(
                                                        alignment: MainAxisAlignment.center,
                                                      ),
                                                  child: 
                                                          Container(
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
                                                      child: 
                                                            Row(
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
                                                )
                                              
                                              
                                               
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      _f(currentTicket.total),
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
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _f(currentTicket.amountTendered!),
                                        style: GoogleFonts.poppins(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
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
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        _f(currentTicket.amountTendered! - currentTicket.total),
                                        style: GoogleFonts.poppins(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        PrintService.printTicket(
                                          businessName: '',
                                          items: currentTicket.items,
                                          total: currentTicket.total,
                                          received: currentTicket.amountTendered!,
                                          change: currentTicket.amountTendered! - currentTicket.total,
                                          paymentMethod: currentTicket.paymentMethod,
                                        );
                                      },
                                      icon: Icon(Icons.print, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                                      label: Text(
                                        'Imprimir previo',
                                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                SizedBox(
                                  width: double.infinity,
                                  child: 
                                   //Cobrar button 
                                      Showcase(
                                          key: _cobrarKey,
                                          description: 'Toca para cobrar los productos en el ticket.',
                                          tooltipPadding: const EdgeInsets.all(12),
                                          tooltipActions: [
                                                    TooltipActionButton(
                                                            type: TooltipDefaultActionType.skip,
                                                            backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                            textStyle: TextStyle(color: Colors.white),
                                                            name: 'Saltar',
                                                          
                                                          ), 
                                                    TooltipActionButton(
                                                      type: TooltipDefaultActionType.next,
                                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                                      textStyle: TextStyle(color: Colors.white),
                                                      name: 'Siguiente',
                                                    
                                                    )
                                                  ],
                                          tooltipActionConfig: TooltipActionConfig(
                                                alignment: MainAxisAlignment.center,
                                              ),
                                          child:  
                                                ElevatedButton(
                                                    onPressed: currentTicket.items.isEmpty
                                                        ? null
                                                        : () {
                                                            if (currentTicket.amountTendered ==
                                                                null) {
                                                              _showPaymentDialog(
                                                                setModalState: setModalState,
                                                              ).then((success) {
                                                                if (success == true) {
                                                                  _processSale();
                                                                  Navigator.pop(context);
                                                                }
                                                              });
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
                                                    child: 
                                                          Text(
                                                                  currentTicket.amountTendered == null
                                                                      ? 'COBRAR'
                                                                      : 'FINALIZAR VENTA',
                                                                  style: GoogleFonts.poppins(
                                                                    fontWeight: FontWeight.bold,
                                                                  ),
                                                                ),                            
                
                                                  ),
                                        )
                                  
                                  

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
    await showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        product: product,
        onSaved: () =>
            Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
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
            BulkProductDialog(productName: product['name'], pricePerKg: price),
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

    if (currentTicket.items.isEmpty) {
      currentTicket.discount = 0.0;
      currentTicket.amountTendered = null;
      currentTicket.paymentMethod = 'Efectivo';
    }

    currentTicket.total = currentTicket.subtotal - currentTicket.discount;
    if (currentTicket.total < 0) currentTicket.total = 0.0;
    if (currentTicket.amountTendered != null &&
        currentTicket.amountTendered! < currentTicket.total) {
      currentTicket.amountTendered = null;
    }
  }
  
  Future<bool?> _showPaymentDialog({StateSetter? setModalState}) async {
    final amountController = TextEditingController();
    String localPaymentMethod = currentTicket.paymentMethod;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f12) {
                final parsedAmount = double.tryParse(amountController.text.replaceAll(",", ""));
                final double amount = parsedAmount ?? currentTicket.total;
                
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
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El monto recibido debe ser mayor o igual al total'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Cobrar - TOTAL: ${_f(currentTicket.total)}',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Método de Pago:',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
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
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  autofocus: true,
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [CurrencyInputFormatter()],
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Monto recibido',
                    labelStyle: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    prefixText: r'$ ',
                    prefixStyle: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  onSubmitted: (_) {
                    final parsedAmount = double.tryParse(amountController.text.replaceAll(",", ""));
                    final double amount = parsedAmount ?? currentTicket.total;
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
                      Navigator.pop(context, true);
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
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final parsedAmount = double.tryParse(amountController.text.replaceAll(",", ""));
                  final double amount = parsedAmount ?? currentTicket.total;
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
                    Navigator.pop(context, true);
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
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  'Aceptar',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ));
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF05e265).withOpacity(0.2)
                : Theme.of(context).dividerColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF05e265)
                  : Theme.of(context).dividerColor.withOpacity(0.1),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive
                    ? const Color(0xFF05e265)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                size: 24,
              ),
              const SizedBox(height: 8),
              FittedBox(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: isActive
                        ? const Color(0xFF05e265)
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showSalesHistoryDialog() async {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            const Icon(Icons.history, color: Color(0xFF05e265)),
            const SizedBox(width: 12),
            Text(
              'Historial de Ventas',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white54),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 500,
          child: FutureBuilder<Map<String, dynamic>>(
            future: CashSessionService.getSessionHistory(_currentSessionId.toString()), // Replace 'session_id' with the actual session ID
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF05e265)),
                );
              }
              List<dynamic> sales = [];
              if (snapshot.hasData && snapshot.data!['success'] == true) {
                sales = snapshot.data!['data'] ?? [];
              }
              
              


              return ListView.separated(
                itemCount: sales.length,
                separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                itemBuilder: (context, index) {
                  final sale = sales[index] ?? {};
                  final DateTime date = sale['date'] != null
                      ? (DateTime.tryParse(sale['date'].toString()) ?? DateTime.now())
                      : DateTime.now();
                  final double total = sale['total'] != null
                      ? (sale['total'] is num ? (sale['total'] as num).toDouble() : double.tryParse(sale['total'].toString()) ?? 0.0)
                      : 0.0;
                  final String paymentMethod = sale['paymentMethod']?.toString() ?? 'Efectivo';
                  final String saleId = sale['_id']?.toString() ?? '000000';
                  final String shortId = saleId.length >= 6 ? saleId.substring(saleId.length - 6).toUpperCase() : saleId;
                  
                  final List items = sale['products'] is List ? sale['products'] as List : [];
                  final String itemsSummary = items.isNotEmpty 
                      ? items.take(2).map((i) {
                          if (i is Map && i['productId'] is Map && i['productId']['name'] != null) {
                            return i['productId']['name'].toString();
                          }
                          return 'Producto';
                        }).join(', ') + (items.length > 2 ? '...' : '')
                      : 'Sin detalles';
               
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05e265).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.receipt_long, color: Color(0xFF05e265), size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Venta #$shortId',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                itemsSummary,
                                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time, 
                                    size: 12, 
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat('dd/MM/yyyy HH:mm').format(date),
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(
                                    Icons.payment, 
                                    size: 12, 
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    paymentMethod,
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), 
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF05e265),
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _confirmCancelSale(context, saleId),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
  
  void _confirmCancelSale(BuildContext context, String saleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          '¿Cancelar venta?',
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Esta acción es irreversible y anulará el ticket seleccionado.',
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Regresar', style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Close confirmation
              final result = await SaleService.cancelSale(saleId);
              if (result['success']) {
                Navigator.pop(context); // Close history dialog to refresh
                _showSalesHistoryDialog(); // Re-open history
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Venta cancelada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'Confirmar Anulación',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
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
          'Procesando pago del Ticket... ${_f(currentTicket.total)}',
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
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Aplicar Descuento',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ingresa el monto de descuento para este ticket:',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: discountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [CurrencyInputFormatter()],
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Monto de descuento',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                prefixText: r'$ ',
                prefixStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor),
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
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final double discount =
                  double.tryParse(discountController.text.replaceAll(",", "")) ?? 0.0;
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
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Aplicar',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Future<void> _showWithdrawalDialog() async {
    showDialog(
      context: context,
      builder: (context) => WithdrawalDialog(
        onSaved: (amount) {
          setState(() {
            _totalWithdrawals += amount;
          });
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
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
                    dropdownColor: Theme.of(context).cardColor,
                    items: categoryFilters.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Text(
                          cat,
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
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
                    dropdownColor: Theme.of(context).cardColor,
                    items: sortOptions.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(
                          sort,
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
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
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
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

  Widget _buildTicketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
