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
  @override
  void initState() {
    super.initState();
    // final provider = Provider.of<ProductProvider>(context, listen: false);
    // if (provider.allProducts.isEmpty) {
    //   //provider.fetchProducts();
    //   provider.fetchInitialProducts(); 
    // }
    _loadUserRole();
  }
  Future<void> _loadUserRole() async {
    final role = await AuthService.getCurrentUserRole();
    setState(() {
      _userRole = role ?? 'cajero';
    });
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
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.fetchProducts(),
          ),
        ],
      ),
      /* Removed FloatingActionButton as requested and moved it to the top */
      body: Container(
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(30)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Colors.white70,
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
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _showFilterDialog,
                      icon: const Icon(Icons.filter_list, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withAlpha(20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Stats dinámicos
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
                  const SizedBox(width: 24), // Increased from 16
                  Expanded(
                    child: StatCard(
                      title: 'Bajo Stock',
                      value: allProducts
                          .where(
                            (p) =>
                                (p['units'] ?? 0) < 5 && (p['units'] ?? 0) > 0,
                          )
                          .length
                          .toString(),
                      icon: Icons.warning,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 24), // Increased from 16
                  Expanded(
                    child: StatCard(
                      title: 'Sin Stock',
                      value: allProducts
                          .where((p) => (p['units'] ?? 0) == 0)
                          .length
                          .toString(),
                      icon: Icons.error,
                      color: const Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Tabla de productos
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: Column(
                    children: [
                      // Encabezado
                      if (!isMobile) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(13),
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
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Categoría',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Stock',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Precio',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Estado',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
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
                                      color: Colors.white,
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
    );
  }
  void _showAddStockModal(Map product) {
    final TextEditingController stockController = TextEditingController();
    bool isSaving = false;
    showDialog(
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
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                          units: newUnits,
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
                            final provider = Provider.of<ProductProvider>(
                              context,
                              listen: false,
                            );
                            provider.fetchProducts();
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
