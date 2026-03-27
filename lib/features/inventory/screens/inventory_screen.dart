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
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
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

  final List<String> stockFilters = [
    'Todos',
    'Bajo Stock',
    'Sin Stock',
  ];

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

  //Onboarding  
  final GlobalKey _addProductKey = GlobalKey(); 
  final GlobalKey _refreshListKey = GlobalKey(); 
  final GlobalKey _filterProductsKey = GlobalKey(); 
  final GlobalKey _productOptionsKey = GlobalKey(); 
  final GlobalKey _addStockKey = GlobalKey(); 


  static const String _InventoryOnboardingKey = 'onboarding_inventory';

  Future<bool> _shouldShowOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_InventoryOnboardingKey) ?? false);
    }

  Future<void> _setOnboardingShown() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_InventoryOnboardingKey, true);
    }

  @override
  void initState() {

    // //Onboarding
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 600), () {
    //     ShowcaseView.get().startShowCase([
    //       _addProductKey,
    //       _refreshListKey,
    //       _filterProductsKey,
    //       _productOptionsKey,
    //       _addStockKey,
    //     ]);
    //   });
    // });


    super.initState();

    _loadUserRole();
    
 
    // Onboarding
    _initOnboarding();

  }

  
   
  Future<void> _initOnboarding() async {
    final shouldShow = await _shouldShowOnboarding();
    if (!shouldShow) return;

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

    await _setOnboardingShown();
  }


  Future<void> _loadUserRole() async {
    final role = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = role ?? 'cajero';
    });
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final now = DateTime.now();

      // Detectamos si el foco actual NO es un TextField/EditableText
      // Para no interferir si el usuario ya está escribiendo manualmente o si el scanner ya está escribiendo en el buscador
      final primaryFocus = FocusManager.instance.primaryFocus;
      bool isInputFocused = primaryFocus != null && 
                            primaryFocus != _keyboardFocusNode &&
                            (primaryFocus.children.isEmpty); // Simple heurística: los campos de texto suelen ser nodos hoja o manejados diferente
      
      // En Flutter, si el primaryFocus es el nodo del TextField, no queremos duplicar datos en nuestro buffer global
      if (primaryFocus != null && primaryFocus.debugLabel != null && primaryFocus.debugLabel!.contains('EditableText')) {
        _barcodeBuffer = '';
        return;
      }

      if (now.difference(_lastKeyEventTime).inMilliseconds > 100) {
        _barcodeBuffer = '';
      }
      _lastKeyEventTime = now;

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_barcodeBuffer.isNotEmpty) {
          setState(() {
            searchQuery = _barcodeBuffer;
            searchController.text = _barcodeBuffer;
            _barcodeBuffer = '';
          });
        }
      } else {
        final character = event.character;
        if (character != null && character.isNotEmpty) {
          _barcodeBuffer += character;
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProductProvider>(context);
    final allProducts = provider.allProducts;
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    // Aplicar filtros
    final filteredProducts = filterProducts(
      products: allProducts,
      searchQuery: searchQuery,
      category: selectedCategoryFilter,
      onlyBulk: filterBulkOnly,
      sortOption: selectedSortOption,
      stockStatus: selectedStockFilter,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventario',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [

                  //Add product button 
                  Showcase(
                          key: _addProductKey,
                          description: 'Toca para agregar un producto.',
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
                  
                  //Refresh list button 
                  Showcase(
                          key: _refreshListKey,
                          description: "Toca para actualizar la lista de productos.", 
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
                                 IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () => provider.fetchProducts(),
                                ),

                  ),



         
        ],
      ),
      /* Removed FloatingActionButton as requested and moved it to the top */
      body: KeyboardListener(
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
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
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
                                  'Categoría',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Stock',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
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
                                  child: Text(
                                    'Acciones',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
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
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage.isNotEmpty
                            ? Center(
                                child: Text(
                                  errorMessage,
                                  style: GoogleFonts.poppins(color: Colors.red),
                                ),
                              )
                            : filteredProducts.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay productos',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  
                                  // Solo el primer producto tendrá showcase (por ejemplo)
                                  final GlobalKey? addStockKey = index == 0 ? _addStockKey : null;
                                  final GlobalKey? actionMenuKey = index == 0 ? _productOptionsKey : null;



                                  return ProductListItem(
                                    id: (product['_id'] ?? '').toString(),
                                    name: product['name'] ?? 'Sin nombre',
                                    category:
                                        product['category'] ?? 'Sin categoría',
                                    stock: (product['units'] ?? 0).toString(),
                                    isBulk: product['isBulk'] ?? false,
                                    price: '\$${product['sellingPrice'] ?? 0}',
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


                                    // SHOWCASE solo para este producto
                                    addStockKey: addStockKey,
                                    actionMenuKey: actionMenuKey,

                                    onDelete: () =>
                                        _deleteProduct(product['_id']),
                                    onEdit: () =>
                                        _showEditProductModal(product),

                                    
                                    onAddStock: () =>
                                        _showAddStockModal(product),
                                    hasWholesalePrice:
                                        product['hasWholesalePrice'] ?? false,
                                    wholesalePrice:
                                        '\$${product['wholesalePrice'] ?? 0}',
                                    wholesaleMinUnits:
                                        product['wholesaleMinUnits'] ?? 0,
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
            Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
      ),
    );
  }
  void _showAddProductModal() {
    showDialog(
      context: context,
      builder: (_) => AddProductDialog(
        onProductAdded: () {
          final provider = Provider.of<ProductProvider>(context, listen: false);
          provider.fetchProducts();
        },
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
          provider.fetchProducts();
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
      provider.fetchProducts();
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
