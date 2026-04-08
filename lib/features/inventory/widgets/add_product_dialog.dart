import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';
import '../screens/barcode_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../../../core/utils/currency_formatter.dart';

class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;
  const AddProductDialog({super.key, required this.onProductAdded});
  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }
  final nameController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final weightController = TextEditingController();
  final unitsController = TextEditingController();
  final mayoreoController = TextEditingController();
  final mayoreoUnitsController = TextEditingController();
  final barcodeController = TextEditingController();
  
  // Package (Paquete) Controllers
  final packageNameController = TextEditingController();
  final packageSalePriceController = TextEditingController();
  final packageUnitsController = TextEditingController(text: '1');
  final packageBarcodeController = TextEditingController();
  final packageSearchController = TextEditingController(); 
  List<Map<String, dynamic>> selectedPackageProducts = [];
  TextEditingController? _internalPackageSearchController;
  double suggestedPackagePrice = 0.0;
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
    if (isLoading) return;
    final name = nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa el nombre')));
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
      units: double.tryParse(unitsController.text) ?? 0,
      buyingPrice: double.tryParse(purchasePriceController.text.replaceAll(",", "")) ?? 0.0,
      sellingPrice: double.tryParse(salePriceController.text.replaceAll(",", "")) ?? 0.0,
      bulkPrice: double.tryParse(weightController.text) ?? 0.0,
      hasWholesalePrice: hasMayoreo,
      wholesalePrice: double.tryParse(mayoreoController.text.replaceAll(",", "")) ?? 0.0,
      wholesaleMinUnits: int.tryParse(mayoreoUnitsController.text) ?? 0,
    );
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          (result['message'] != null &&
                  result['message'].toString().toLowerCase().contains('barcode already exists'))
              ? 'El código de barras ya existe'
              : (result['message'] ??
                  (result['success'] == true
                      ? 'Producto añadido correctamente'
                      : 'Error al añadir producto')),
        ),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (result['success'] == true) {
      widget.onProductAdded();
      Navigator.pop(context);
    }
  }

  Future<void> savePackage() async {
    if (isLoading) return;
    final name = packageNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el nombre del paquete')));
      return;
    }
    if (selectedPackageProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un producto al paquete')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    // Calculamos el precio de compra sugerido como la suma de los precios de compra de los componentes
    double totalBuyingPrice = 0;
    for (var p in selectedPackageProducts) {
      totalBuyingPrice += (p['buyingPrice'] as num?)?.toDouble() ?? 0.0;
    }

    final result = await InventoryService.createProduct(
      name: name,
      barcode: packageBarcodeController.text.isEmpty ? 'N/A' : packageBarcodeController.text,
      isBulk: false,
      weight: 1.0, 
      category: 'Paquetes',
      units: double.tryParse(packageUnitsController.text) ?? 1.0,
      buyingPrice: totalBuyingPrice,
      sellingPrice: double.tryParse(packageSalePriceController.text.replaceAll(",", "")) ?? suggestedPackagePrice,
      bulkPrice: 0.0,
      hasWholesalePrice: false,
      wholesalePrice: 0.0,
      wholesaleMinUnits: 0,
      components: selectedPackageProducts,
    );

    setState(() {
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? (result['success'] == true ? 'Paquete añadido correctamente' : 'Error')),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
      ),
    );

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
    unitsController.dispose();
    mayoreoController.dispose();
    mayoreoUnitsController.dispose();
    barcodeController.dispose();
    packageNameController.dispose();
    packageSalePriceController.dispose();
    packageBarcodeController.dispose();
    packageSearchController.dispose();
    packageUnitsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Helper para inputs consistentes con MD3
  InputDecoration _inputDecoration(BuildContext context, {
    required String labelText,
    String? prefixText,
    TextStyle? prefixStyle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: labelText,
      prefixText: prefixText,
      prefixStyle: prefixStyle ?? GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
      labelStyle: GoogleFonts.poppins(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      floatingLabelStyle: GoogleFonts.poppins(
        color: const Color(0xFF05e265),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: isDark
          ? Theme.of(context).colorScheme.onSurface.withOpacity(0.07)
          : Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark
              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.3)
              : Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF05e265), width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          if (_tabController.index == 0) {
            saveProduct();
          } else {
            savePackage();
          }
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Añadir Producto',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Producto'),
              Tab(text: 'Paquete'),
            ],
            labelColor: const Color(0xFF05e265),
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: const Color(0xFF05e265),
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal, fontSize: 13),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 500, // Fijamos una altura razonable para el TabBarView
        child: TabBarView(
          controller: _tabController,
          children: [
            // TAB 1: PRODUCTO
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      autofocus: true,
                      controller: nameController,
                      decoration: _inputDecoration(context, labelText: 'Nombre del Producto'),
                      style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: barcodeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration(context, labelText: 'CB (Código de Barras)'),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
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
                          onPressed: () => _scanBarcodeWithOptions(context, barcodeController),
                          tooltip: 'Escanear Código de Barras',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: isBulk,
                        onChanged: (value) {
                          setState(() {
                            isBulk = value;
                            if (isBulk) {
                              selectedCategory = 'Abarrotes';
                              weightController.text = '1';
                            } else {
                              weightController.clear();
                            }
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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                    dropdownColor: Theme.of(context).cardColor,
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    decoration: _inputDecoration(context, labelText: 'Categoría'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: unitsController,
                    keyboardType: TextInputType.numberWithOptions(decimal: isBulk),
                    inputFormatters: isBulk
                        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                        : [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration(context, labelText: isBulk ? 'KG CT' : 'Unidades'),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: purchasePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: _inputDecoration(
                      context,
                      labelText: isBulk ? 'Precio de Compra (por 1 KG CT)' : 'Precio de Compra',
                      prefixText: r'$ ',
                    ),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: _inputDecoration(
                      context,
                      labelText: isBulk ? 'Precio de Venta (por 1 KG CT)' : 'Precio de Venta',
                      prefixText: r'$ ',
                    ),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 16),
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
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (hasMayoreo) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: mayoreoController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [CurrencyInputFormatter()],
                            decoration: _inputDecoration(
                              context,
                              labelText: 'Precio Mayoreo',
                              prefixText: r'$ ',
                            ),
                            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: mayoreoUnitsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: _inputDecoration(context, labelText: 'Mínimo Unidades'),
                            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),

            // TAB 2: PAQUETE
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        TextField(
                          controller: packageNameController,
                          decoration: _inputDecoration(context, labelText: 'Nombre del Paquete'),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        ),
                        const SizedBox(height: 16),

                        // Buscador de productos para el paquete
                        Consumer<ProductProvider>(
                          builder: (context, provider, _) {
                            final allProducts = provider.allProducts;
                            return Autocomplete<Map<String, dynamic>>(
                              displayStringForOption: (option) => option['name'],
                              optionsBuilder: (textEditingValue) {
                                if (textEditingValue.text.isEmpty) return const Iterable.empty();
                                return allProducts
                                    .where((p) => p['name']
                                        .toString()
                                        .toLowerCase()
                                        .contains(textEditingValue.text.toLowerCase()))
                                    .map((p) => p as Map<String, dynamic>);
                              },
                              onSelected: (product) {
                                setState(() {
                                  // Añadimos con cantidad inicial 1
                                  final pWithQty = Map<String, dynamic>.from(product);
                                  pWithQty['quantity'] = 1;
                                  selectedPackageProducts.add(pWithQty);
                                  
                                  suggestedPackagePrice += (product['sellingPrice'] as num).toDouble();
                                  packageSalePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                  _internalPackageSearchController?.clear();
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                _internalPackageSearchController = controller;
                                return TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  decoration: _inputDecoration(context, labelText: 'Buscar productos para añadir...').copyWith(
                                    prefixIcon: const Icon(Icons.search, color: Color(0xFF05e265)),
                                  ),
                                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Productos en el paquete:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: selectedPackageProducts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text('No hay productos añadidos', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13)),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: selectedPackageProducts.length,
                                  itemBuilder: (context, index) {
                                    final p = selectedPackageProducts[index];
                                    final stock = (p['units'] ?? 0);
                                    final qty = p['quantity'] ?? 1;

                                    return ListTile(
                                      title: Text(p['name'], style: GoogleFonts.poppins(fontSize: 14)),
                                      subtitle: Text('Estado: ${stock == 0 ? "Sin Stock" : stock < 5 ? "Bajo Stock ($stock)" : "En Stock ($stock)"}', 
                                        style: GoogleFonts.poppins(fontSize: 11, color: stock == 0 ? Colors.red : stock < 5 ? Colors.orange : Colors.green)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Controles de cantidad
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 18),
                                            onPressed: qty > 1 ? () {
                                              setState(() {
                                                p['quantity'] = qty - 1;
                                                suggestedPackagePrice -= (p['sellingPrice'] as num).toDouble();
                                                packageSalePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                              });
                                            } : null,
                                          ),
                                          Text('$qty', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 18),
                                            onPressed: () {
                                              setState(() {
                                                p['quantity'] = qty + 1;
                                                suggestedPackagePrice += (p['sellingPrice'] as num).toDouble();
                                                packageSalePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                              });
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          Text(CurrencyFormatter.format((p['sellingPrice'] as num).toDouble() * qty), 
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF05e265))),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                            onPressed: () {
                                              setState(() {
                                                suggestedPackagePrice -= (p['sellingPrice'] as num).toDouble() * qty;
                                                selectedPackageProducts.removeAt(index);
                                                packageSalePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05e265).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Sugerido:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              Text(CurrencyFormatter.format(suggestedPackagePrice), 
                                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF05e265))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: packageSalePriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: _inputDecoration(
                            context,
                            labelText: 'Precio Final del Paquete',
                            prefixText: r'$ ',
                          ),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: packageUnitsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: _inputDecoration(context, labelText: 'Stock Inicial del Paquete'),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : (_tabController.index == 0 ? saveProduct : savePackage),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF05e265),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  _tabController.index == 0 ? 'Añadir Producto' : 'Crear Paquete',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
        ),
      ],
    ));
  }

  Future<void> _scanBarcodeWithOptions(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const BarcodeScannerModal(),
    );
    if (result != null && mounted) {
      setState(() {
        controller.text = result;
      });
    }
  }
}
