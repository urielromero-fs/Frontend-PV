import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';
import 'barcode_scanner.dart';
import 'package:flutter/services.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<dynamic> allProducts = []; //Original list
  List<dynamic> filteredProducts = []; //Filtered list for search


  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();


  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchProducts(); // cargar productos al iniciar
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await InventoryService.getProducts();

    if (result['success'] == true) {
      setState(() {
        allProducts = result['data'];
        filteredProducts = List.from(allProducts); // Inicialmente, mostrar todos los productos
        isLoading = false;
      });
    } else {
      setState(() {
        errorMessage = result['message'] ?? 'Error desconocido';
        isLoading = false;
      });
    }
  }


  void filterProducts(String query) {

      setState(() {

        searchQuery = query;

        if(query.isEmpty){
          filteredProducts = List.from(allProducts);
        } else {
          filteredProducts = allProducts.where((product) {
            final name = product['name']?.toString().toLowerCase() ?? '';
            final barcode = (product['barcode'] ?? '').toString().toLowerCase();
            final searchLower = query.toLowerCase();

            return name.contains(searchLower) || barcode.contains(searchLower);

          }).toList();
        }
        
      });

  }



  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchProducts,

          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           //_showAddProductModal(context, fetchProducts);
           _showAddProductModal();
        },
        backgroundColor: const Color(0xFF05e265),
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add),
      ),
      body: Container(
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

           Container(
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(
                             color: Colors.white.withAlpha(13),
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: Colors.white.withAlpha(26)),
                           ),
                           child: Row(
                             children: [
                               Expanded(
                                 child: TextField(
                                    controller: searchController,
                                    onChanged: filterProducts,
                                    decoration: InputDecoration(
                                      hintText: 'Buscar por nombre o código...',
                                      hintStyle: GoogleFonts.poppins(color: Colors.white70),
                                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                                      border: InputBorder.none,
                                    ),
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                               ),
                               const SizedBox(width: 16),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                 decoration: BoxDecoration(
                                   color: const Color(0xFF05e265),
                                   borderRadius: BorderRadius.circular(8),
                                 ),
                                 child: Row(
                                   mainAxisSize: MainAxisSize.min,
                                   children: [
                                     const Icon(Icons.filter_list, color: Colors.white, size: 20),
                                     const SizedBox(width: 8),
                                     Text(
                                       'Filtrar',
                                       style: GoogleFonts.poppins(
                                         color: Colors.white,
                                         fontWeight: FontWeight.w600,
                                       ),
                                     ),
                                   ],
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
                    child: _StatCard(
                      title: 'Total Productos',
                      value: allProducts.length.toString(),
                      icon: Icons.inventory,
                      color: const Color(0xFF05e265),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _StatCard(
                      title: 'Bajo Stock',
                      value: allProducts.where((p) => (p['units'] ?? 0) < 5 && (p['units'] ?? 0) > 0).length.toString(),
                      icon: Icons.warning,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: _StatCard(
                      title: 'Sin Stock',
                      value: allProducts.where((p) => (p['units'] ?? 0) == 0).length.toString(),
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
                            Expanded(flex: 2, child: Text('Producto', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Categoría', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Stock', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Precio', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Estado', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                            Expanded(child: Text('Acciones', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),

                      // Lista de productos
                      Expanded(
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : errorMessage.isNotEmpty
                                ? Center(child: Text(errorMessage, style: GoogleFonts.poppins(color: Colors.red)))
                                : filteredProducts.isEmpty
                                    ? Center(child: Text('No hay productos', style: GoogleFonts.poppins(color: Colors.white70)))
                                    : ListView.builder(
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product = filteredProducts[index];
                                          return _ProductRow(
                                            id: (product['_id'] ?? '').toString(),
                                            name: product['name'] ?? 'Sin nombre',
                                            category: product['category'] ?? 'Sin categoría',
                                            stock: (product['units'] ?? 0).toString(),
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

                                            onDelete: () => _deleteProduct(product['_id']),
                                            onEdit: () => _showEditProductModal(product),
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


    void _showAddProductModal() {
      showDialog(
        context: context,
        builder: (_) => AddProductDialog(
          onProductAdded: fetchProducts,
        ),
      );
    }

    void _showEditProductModal(Map product) {
      showDialog(
        context: context,
        builder: (_) => EditProductDialog(
          product: product,
          onProductUpdated: fetchProducts,
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

      if (result['success'] == true) {
        fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }





}






class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {

  final String id;
  final String name;
  final String category;
  final String stock;
  final String price;
  final String status;
  final Color statusColor;

  //Acciones
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProductRow({
      required this.id,
      required this.name,
      required this.category,
      required this.stock,
      required this.price,
      required this.status,
      required this.statusColor,
      required this.onDelete,
      required this.onEdit
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withAlpha(26)))),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500))),
          Expanded(child: Text(category, style: GoogleFonts.poppins(color: Colors.white70))),
          Expanded(child: Text(stock, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500))),
          Expanded(child: Text(price, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withAlpha(51), borderRadius: BorderRadius.circular(12)),
              child: Text(status, textAlign: TextAlign.center, style: GoogleFonts.poppins(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),

           Expanded(
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),



        ],



      ),
    );
  }
}

class AddProductDialog extends StatefulWidget{

    final VoidCallback onProductAdded;

    const AddProductDialog({super.key, required this.onProductAdded});

    @override
    State<AddProductDialog> createState() => _AddProductDialogState();

}

class EditProductDialog extends StatefulWidget {
  final Map product;
  final VoidCallback onProductUpdated;

  const EditProductDialog({
    super.key,
    required this.product,
    required this.onProductUpdated,
  });

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}


class _AddProductDialogState extends State<AddProductDialog> {

  final nameController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final weightController = TextEditingController();
  //final categoryController = TextEditingController();
  final unitsController = TextEditingController();
  final mayoreoController = TextEditingController();
  final barcodeController = TextEditingController();

  bool isBulk = false;
  bool hasMayoreo = false;
  bool isLoading = false;


  String selectedCategory = 'Sin categoría';

  final List<String> categories = [
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
      "Otros",
    ];  




  Future<void> saveProduct() async {
    final name = nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

   
    final result = await InventoryService.createProduct(
      name: name,
      barcode: barcodeController.text.isEmpty ? 'N/A' : barcodeController.text,
      isBulk: isBulk,
      weight: double.tryParse(weightController.text) ?? 0.0,

      category: selectedCategory,

      units: int.tryParse(unitsController.text) ?? 0,
      buyingPrice: double.tryParse(purchasePriceController.text) ?? 0.0,
      sellingPrice: double.tryParse(salePriceController.text) ?? 0.0,
      bulkPrice: double.tryParse(weightController.text) ?? 0.0,
      hasWholesalePrice: hasMayoreo,
      wholesalePrice: double.tryParse(mayoreoController.text) ?? 0.0,


    
      
    );

    setState(() {
      isLoading = false;
    });

    if (result['success'] == true) {
      widget.onProductAdded();
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    weightController.dispose();
    //categoryController.dispose();
    unitsController.dispose();
    mayoreoController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

    @override
      Widget build(BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: Text(
            'Añadir Producto',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Product Name
                    // Product Name con margen superior
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0), // <- margen arriba
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Producto',
                        labelStyle: GoogleFonts.poppins(color: Colors.white70),
                         floatingLabelStyle: GoogleFonts.poppins(
                              color: Colors.white, // color cuando flota
                              fontWeight: FontWeight.w500,
                            ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFF05e265)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),


                    // Barcode Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeController,
                            decoration: InputDecoration(
                              labelText: 'CB (Código de Barras)',
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
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF05e265),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                            onPressed: () {
                              _scanBarcode(context, barcodeController);
                            },
                            tooltip: 'Escanear Código de Barras',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bulk Option
                    Row(
                      children: [
                        Switch(
                          value: isBulk,
                          onChanged: (value) {
                            setState(() {
                              isBulk = value;
                            });
                          },
                          activeThumbColor: const Color(0xFF05e265),
                          activeTrackColor: const Color(0xFF05e265).withAlpha(77),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade700,
                        ),
                        Text(
                          '¿Es a granel?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight (only for bulk products)
                    if (isBulk) ...[
                      TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
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
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                    ],

                  //Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: GoogleFonts.poppins(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                      },
                      dropdownColor: const Color(0xFF1a1a1a), 
                      style: GoogleFonts.poppins(color: Colors.white), 
                      decoration: InputDecoration(
                        labelText: 'Categoría',
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
                    const SizedBox(height: 16),


                    // Units
                    TextField(
                      controller: unitsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Unidades',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Purchase Price
                    TextField(
                      controller: purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio de Compra',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Sale Price
                    TextField(
                      controller: salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio de Venta',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Mayoreo Option
                    Row(
                      children: [
                        Switch(
                          value: hasMayoreo,
                          onChanged: (value) {
                            setState(() {
                              hasMayoreo = value;
                            });
                          },
                          activeThumbColor: const Color(0xFF05e265),
                          activeTrackColor: const Color(0xFF05e265).withAlpha(77),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade700,
                        ),
                        Text(
                          '¿Tiene precio mayoreo?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (hasMayoreo) ...[
                      TextField(
                        controller: mayoreoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Precio Mayoreo',
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
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

          
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : saveProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Añadir',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      }






  
}


class _EditProductDialogState extends State<EditProductDialog> {

  final nameController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final weightController = TextEditingController();
  //final categoryController = TextEditingController();
  final unitsController = TextEditingController();
  final mayoreoController = TextEditingController();
  final barcodeController = TextEditingController();

  bool isBulk = false;
  bool hasMayoreo = false;
  bool isLoading = false;

  String selectedCategory = 'Sin categoría';

  final List<String> categories = [
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
  "Otros",
  ];  

  @override
  void initState() {
    super.initState();


    nameController.text = widget.product['name']?.toString() ?? '';
    barcodeController.text = widget.product['barcode']?.toString() ?? '';
    unitsController.text = (widget.product['units'] ?? 0).toString();
    purchasePriceController.text = (widget.product['buyingPrice'] ?? 0).toString();
    salePriceController.text = (widget.product['sellingPrice'] ?? 0).toString();
    weightController.text = (widget.product['weight'] ?? 0).toString();


    selectedCategory = widget.product['category']?.toString() ?? 'Sin categoría';
    

    mayoreoController.text = (widget.product['wholesalePrice'] ?? 0).toString();

    isBulk = widget.product['isBulk'] ?? false;
    hasMayoreo = widget.product['hasWholesalePrice'] ?? false;
  }

    Future<void> updateProduct() async {
      final id = widget.product['_id']?.toString() ?? '';

      if (id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID inválido')),
        );
        return;
      }

      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el nombre')),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      final result = await InventoryService.updateProduct(
        id: id,
        name: nameController.text.trim(),
        barcode: barcodeController.text,
        isBulk: isBulk,
        weight: double.tryParse(weightController.text) ?? 0.0,

        category: selectedCategory,

        units: int.tryParse(unitsController.text) ?? 0,
        buyingPrice: double.tryParse(purchasePriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(salePriceController.text) ?? 0.0,
        bulkPrice: double.tryParse(weightController.text) ?? 0.0,
        hasWholesalePrice: hasMayoreo,
        wholesalePrice: double.tryParse(mayoreoController.text) ?? 0.0,
      );

      setState(() {
        isLoading = false;
      });

      if (result['success'] == true) {
        widget.onProductUpdated();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error al actualizar')),
        );
      }
    }

      @override
      Widget build(BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: Text(
            'Actualizar Producto',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // Product Name
                    // Product Name con margen superior
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0), // <- margen arriba
                    child: TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Producto',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),


                    // Barcode Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: barcodeController,
                            decoration: InputDecoration(
                              labelText: 'CB (Código de Barras)',
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
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF05e265),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                            onPressed: () {
                              _scanBarcode(context, barcodeController);
                            },
                            tooltip: 'Escanear Código de Barras',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bulk Option
                    Row(
                      children: [
                        Switch(
                          value: isBulk,
                          onChanged: (value) {
                            setState(() {
                              isBulk = value;
                            });
                          },
                          activeThumbColor: const Color(0xFF05e265),
                          activeTrackColor: const Color(0xFF05e265).withAlpha(77),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade700,
                        ),
                        Text(
                          '¿Es a granel?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Weight (only for bulk products)
                    if (isBulk) ...[
                      TextField(
                        controller: weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Peso (kg)',
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
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                    ],

                  //Category Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      items: categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category, style: GoogleFonts.poppins(color: Colors.white)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                            setState(() {
                              selectedCategory = value;
                            });
                          }
                      },
                      dropdownColor: const Color(0xFF1a1a1a), 
                      style: GoogleFonts.poppins(color: Colors.white), 
                      decoration: InputDecoration(
                        labelText: 'Categoría',
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
                    const SizedBox(height: 16),


                    // Units
                    TextField(
                      controller: unitsController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Unidades',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Purchase Price
                    TextField(
                      controller: purchasePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio de Compra',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Sale Price
                    TextField(
                      controller: salePriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Precio de Venta',
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
                      style: GoogleFonts.poppins(color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Mayoreo Option
                    Row(
                      children: [
                        Switch(
                          value: hasMayoreo,
                          onChanged: (value) {
                            setState(() {
                              hasMayoreo = value;
                            });
                          },
                          activeThumbColor: const Color(0xFF05e265),
                          activeTrackColor: const Color(0xFF05e265).withAlpha(77),
                          inactiveThumbColor: Colors.grey.shade400,
                          inactiveTrackColor: Colors.grey.shade700,
                        ),
                        Text(
                          '¿Tiene precio mayoreo?',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (hasMayoreo) ...[
                      TextField(
                        controller: mayoreoController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Precio Mayoreo',
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
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),

          
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : updateProduct,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Actualizar',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        );
      }


      @override
      void dispose() {
        nameController.dispose();
        purchasePriceController.dispose();
        salePriceController.dispose();
        weightController.dispose();
        //categoryController.dispose();
        unitsController.dispose();
        mayoreoController.dispose();
        barcodeController.dispose();
        super.dispose();
      }
    }



Future<void> _scanBarcode(BuildContext context, TextEditingController barcodeController) async {
  // Abrimos la página de scanner
  final scannedCode = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      builder: (_) => BarcodeScannerPage(), // el widget que creamos antes
    ),
  );

  if (scannedCode != null && scannedCode.isNotEmpty) {
    // Colocamos el código escaneado en el TextField
    barcodeController.text = scannedCode;
  }
}

void _scanBarcodeWithTwoOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: Text(
          'Escanear Código de Barras',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona el método de escaneo:',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScanOption(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scanWithCamera();
                  },
                ),
                _ScanOption(
                  icon: Icons.qr_code_scanner,
                  label: 'Scanner',
                  onTap: () {
                    Navigator.of(context).pop();
                    _scanWithHardware();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancelar',
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      );
    },
  );
}

void _scanWithCamera() {
  // TODO: Implement camera scanning
  // This would use mobile_scanner or qr_code_scanner package
}

void _scanWithHardware() {
  // TODO: Implement hardware scanner
  // This would connect to external barcode scanner via Bluetooth/USB
}

class _ScanOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ScanOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(26)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xFF05e265),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
