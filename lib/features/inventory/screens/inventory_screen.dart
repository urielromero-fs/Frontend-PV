
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import 'barcode_scanner.dart';
import 'package:pv26/core/utils/product_filters.dart';
import '../providers/product_provider.dart';
import 'package:pv26/features/auth/services/auth_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/product_list_item.dart';
import '../widgets/add_product_dialog.dart';
import '../widgets/edit_product_dialog.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/fast_add_inventory_dialog.dart';
import '../providers/category_provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../users/services/users_service.dart'; 
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pv26/core/network/api_helper.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class InventoryScreen extends StatefulWidget {
  final String? branchId; 
  final bool showAppBar;
  const InventoryScreen({super.key, this.branchId, this.showAppBar = true});
  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}
class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> allProducts = []; //Original list
  List<dynamic> filteredProducts = []; //Filtered list for search
  bool isLoading = false;
  String errorMessage = '';
  String _userRole = 'cajero'; // Default restriction
  
  // Filtros locales
  String searchQuery = '';
  String selectedCategoryFilter = 'Todas';
  String selectedSortOption = 'Ninguno';
  String selectedStockFilter = 'Todos';
  bool filterBulkOnly = false;
  final TextEditingController searchController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  String _barcodeBuffer = '';
  DateTime _lastKeyEventTime = DateTime.now();
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');

  final List<String> stockFilters = [
    'Todos',
    'Bajo Stock',
    'Sin Stock',
  ];




  final List<String> sortOptions = [
    'Ninguno',
    'Precio Ascendente',
    'Precio Descendente',
  ];

  //Onboarding  
  final GlobalKey _addProductKey = GlobalKey(); 
  final GlobalKey _refreshListKey = GlobalKey(); 
  final GlobalKey _filterProductsKey = GlobalKey(); 
  final GlobalKey _productOptionsKey = GlobalKey(); 
  final GlobalKey _addStockKey = GlobalKey(); 

  Map<String, dynamic> _onboarding = {
      'isCompleted': false,
      'stepsCompleted': {
        'inventory': false,
      },
    };

  final FocusNode _searchFocusNode = FocusNode();
  
  String? branchId; 
  bool _isDownloading = false;


  @override
  void initState() {



    super.initState();

    _loadOnboarding().then((_) {
      _initOnboarding(); 
    });

    _loadUserRole();

    //_initBranch();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBranch();
    });

  }

  Future<void> _initBranch() async {
    
      branchId = await AuthService.getCurrentUserLocation();

      Provider.of<ProductProvider>(context, listen: false)
          .fetchProducts(branchId: branchId);
  }

  
   
  Future<void> _initOnboarding() async {


    if(_onboarding['isCompleted'] == true) return;

    if(_onboarding['stepsCompleted']['inventory'] == true) return; 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        ShowcaseView.get().startShowCase([   
          _addProductKey,
           _refreshListKey,
           _filterProductsKey,
           _productOptionsKey,
           _addStockKey,
        ]);
      });
    });

      await _markInventoryOnboardingCompleted(); 
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

  Future<void> _markInventoryOnboardingCompleted() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _onboarding['stepsCompleted']['inventory'] = true;
    });

    await prefs.setString('user_onboarding', jsonEncode(_onboarding));

    final result = await UsersService.updateOnboardingStep(step: 'inventory');

    if (!result['success']) {
      print('Error al actualizar onboarding: ${result['message']}');
    }

  }
  

  Future<void> _loadUserRole() async {
    final role = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = role ?? 'cajero';
    });
  }




  Future<void> _downloadInventory() async {
  if (_isDownloading) return;

  setState(() {
    _isDownloading = true;
  });

  try {
    final result = await InventoryService.downloadProductsExcel(
      locationId: branchId!,
    );

     if (!result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      return;
    }

    final bytes = result['bytes'] as Uint8List;
    final filename = result['filename'] ?? 'products.xlsx';

    if (result['success']) {
      final bytes = result['bytes'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Descarga iniciada...')),
      );

     
      if (kIsWeb) {
        _downloadFileWeb(bytes, filename);
      } else {
       
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Archivo listo en memoria')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }

  

  setState(() {
    _isDownloading = false;
  });
}


void _downloadFileWeb(Uint8List bytes, String filename) {
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);

  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();

  web.URL.revokeObjectURL(url);
}


  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }


  
void _handleKeyEvent(KeyEvent event) {
  if (event is! KeyDownEvent) return;

  final now = DateTime.now();
  final character = event.character;

  // Solo trabajamos si hay carácter válido
  if (character == null || character.isEmpty) return;

  // Detectamos foco
  if (!_searchFocusNode.hasFocus) {
    _searchFocusNode.requestFocus();
  }



  // Detectamos si viene del scanner (teclas rápidas) o del teclado normal
  final diff = now.difference(_lastKeyEventTime).inMilliseconds;
  _lastKeyEventTime = now;

  if (diff > 100) {
    // Teclado normal: dejamos que el TextField lo maneje
    return;
  }

  // Scanner: acumulamos en el buffer
  _barcodeBuffer += character;

  // Enter del scanner
  if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.isNotEmpty) {
    searchController.text = _barcodeBuffer;
    searchQuery = _barcodeBuffer;
    _barcodeBuffer = '';
    setState(() {});
  }
}



  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final bool isMobile = MediaQuery.of(context).size.width < 600;


    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          'Inventario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: isMobile ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ) : null,
        actions: [




                  //Add product button 
                  Showcase(
                          key: _addProductKey,
                          description: 'Toca para agregar un producto.',
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
                                  onPressed: _showAddProductModal,
                                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                                  label: Text(
                                    'Agregar producto',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF05e265),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),

                  ),
                  const SizedBox(width: 8),
                  
                  //Add inventory button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => FastAddInventoryDialog(branchId: branchId),
                      );
                    },
                    icon: const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.white),
                    label: Text(
                      'Agregar inventario',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  



                  const SizedBox(width: 8),

                  //Download button
                  ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadInventory,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.download, size: 18, color: Colors.white),
                    label: Text(
                      _isDownloading ? 'Descargando...' : 'Exportar',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                 
                 
                  //Refresh list button 
                  Showcase(
                          key: _refreshListKey,
                          description: "Toca para actualizar la lista de productos.", 
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
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => provider.fetchProducts(branchId: branchId),
                                ),

                  ),



         
        ],
      ) : null,
      /* Removed FloatingActionButton as requested and moved it to the top */
      body: 
      KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,

        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          focusNode: _searchFocusNode,
                          controller: searchController,
                          onChanged: (value) {
                            _searchQueryNotifier.value = value;
                          },
                          decoration: InputDecoration(
                            hintText: 'Buscar producto...',
                            hintStyle: GoogleFonts.poppins(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                  //Filter products button 
                  Showcase(
                          key: _filterProductsKey,
                          description: "Toca para filtrar productos por stock o categoría, o para ordenarlos.", 
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
                                  onPressed: _showFilterDialog,
                                  icon: Icon(Icons.filter_list, color: Theme.of(context).colorScheme.onSurface, size: 20),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.05),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),

                  ),


                      
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatGrid(allProducts, isMobile),
                const SizedBox(height: 24),

              // Tabla de productos
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      // Encabezado
                      if (!isMobile) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withOpacity(0.03),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Producto',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Departamento',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: 
                                   //actions products button 
                              Showcase(
                                      key: _addStockKey,
                                      description: "Toca para agregar stock de forma más rápida.", 
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
                                      child:  Text(
                                              'Stock',
                                              style: GoogleFonts.poppins(
                                                color: Theme.of(context).colorScheme.onSurface,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                                        

                                  ),
                                
                                
                              ),
                              Expanded(
                                child: Text(
                                  'Precio',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Estado',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: 
                                  
                                //actions products button 
                              Showcase(
                                      key: _productOptionsKey,
                                      description: "Toca para editar o eliminar el producto.", 
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
                                      child:   Text(
                                                'Acciones',
                                                style: GoogleFonts.poppins(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            

                                  ),

    
                                  
                                 
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(color: Colors.white24),
                      ],
                      // Lista de productos
                      Expanded(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _searchQueryNotifier,
                          builder: (context, query, _) {
                            final filteredProducts = filterProducts(
                              products: provider.allProducts,
                              searchQuery: query,
                              category: selectedCategoryFilter,
                              onlyBulk: filterBulkOnly,
                              sortOption: selectedSortOption,
                              stockStatus: selectedStockFilter,
                            );

                            if (isLoading) {
                              return const Center(child: CircularProgressIndicator(color: Color(0xFF05e265)));
                            }

                            if (errorMessage.isNotEmpty) {
                              return Center(child: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.redAccent)));
                            }

                            if (filteredProducts.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                    const SizedBox(height: 16),
                                    Text('No se encontraron productos',
                                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return ProductListItem(
                                  id: (product['_id'] ?? '').toString(),
                                  name: product['name'] ?? 'Sin nombre',
                                  category: product['category'] ?? 'Sin categoría',
                                  stock: (product['units'] ?? 0).toString(),
                                  isBulk: product['isBulk'] ?? false,
                                  price: '\$ ${product['sellingPrice'] ?? 0}',
                                  status: (product['units'] ?? 0) == 0
                                      ? 'Sin Stock'
                                      : (product['units'] ?? 0) < 5
                                      ? 'Bajo Stock'
                                      : 'En Stock',
                                  statusColor: (product['units'] ?? 0) == 0
                                      ? const Color(0xFFE91E63)
                                      : (product['units'] ?? 0) < 5
                                      ? const Color(0xFFFF9800)
                                      : const Color(0xFF05e265),
                                  userRole: _userRole,
                                  onDelete: () => _deleteProduct(product['_id']),
                                  onEdit: () => _showEditProductModal(product),
                                  onAddStock: () => _showAddStockModal(product),
                                  hasWholesalePrice: product['hasWholesalePrice'] ?? false,
                                  wholesalePrice: '\$ ${product['wholesalePrice'] ?? 0}',
                                  wholesaleMinUnits: product['wholesaleMinUnits'] ?? 0,
                                );
                              },
                            );
                          },
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
    ));
  }
  
  
  
  void _showAddStockModal(Map product) {
    showDialog(
      context: context,
      builder: (context) => AddStockDialog(
        product: product,
        onSaved: () =>
            Provider.of<ProductProvider>(context, listen: false).fetchProducts(branchId: branchId),
      ),
    );
  }
  
  
 

      void _showAddProductModal() {
      final provider = Provider.of<ProductProvider>(context, listen: false);

      showDialog(
        context: context,
        builder: (_) => AddProductDialog(
          onProductAdded: () {
            provider.fetchProducts(branchId: branchId);
          },
          branchId: branchId,
        ),
      );
    }


  void _showEditProductModal(Map product) {
    showDialog(
      context: context,
      builder: (_) => EditProductDialog(
        product: product,
        onProductUpdated: () {
          final provider = Provider.of<ProductProvider>(context, listen: false);
          provider.fetchProducts(branchId: branchId);
        },
      ),
    );
  }
  Future<void> _deleteProduct(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que quieres eliminar este producto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final result = await InventoryService.deleteProduct(id);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (result['success'] == true) {
      provider.fetchProducts(branchId: branchId);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result['message'])));
    }
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
                  // Categoría (Departamento)
                  Consumer<CategoryProvider>(
                    builder: (context, catProvider, _) {
                      final categories = ['Todas', ...catProvider.categories];
                      if (!categories.contains(selectedCategoryFilter)) {
                        selectedCategoryFilter = 'Todas';
                      }
                      return DropdownButtonFormField<String>(
                        value: selectedCategoryFilter,
                        dropdownColor: const Color(0xFF1a1a1a),
                        items: categories.map((cat) {
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
                        decoration: const InputDecoration(labelText: 'Departamento'),
                      );
                    },
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
                  // Stock
                  DropdownButtonFormField<String>(
                    value: selectedStockFilter,
                    dropdownColor: const Color(0xFF1a1a1a),
                    items: stockFilters.map((stock) {
                      return DropdownMenuItem(
                        value: stock,
                        child: Text(
                          stock,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedStockFilter = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Estado de Stock'),
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
                  selectedStockFilter = 'Todos';
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
                setState(() {}); 
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

  Widget _buildStatGrid(List<dynamic> allProducts, bool isMobile) {
    final lowStockCount = allProducts
        .where((p) => (p['units'] ?? 0) < 5 && (p['units'] ?? 0) > 0)
        .length;
    final outOfStockCount = allProducts.where((p) => (p['units'] ?? 0) == 0).length;

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Productos',
                  value: allProducts.length.toString(),
                  icon: Icons.inventory,
                  color: const Color(0xFF05e265),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Bajo Stock',
                  value: lowStockCount.toString(),
                  icon: Icons.warning,
                  color: const Color(0xFFFF9800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Sin Stock',
                  value: outOfStockCount.toString(),
                  icon: Icons.error,
                  color: const Color(0xFFE91E63),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox()),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Productos',
            value: allProducts.length.toString(),
            icon: Icons.inventory,
            color: const Color(0xFF05e265),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: StatCard(
            title: 'Bajo Stock',
            value: lowStockCount.toString(),
            icon: Icons.warning,
            color: const Color(0xFFFF9800),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: StatCard(
            title: 'Sin Stock',
            value: outOfStockCount.toString(),
            icon: Icons.error,
            color: const Color(0xFFE91E63),
          ),
        ),
      ],
    );
  }
}
