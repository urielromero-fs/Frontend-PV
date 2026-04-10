

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';
import '../screens/barcode_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../../../core/utils/currency_formatter.dart';

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

class _EditProductDialogState extends State<EditProductDialog> {
  final nameController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final weightController = TextEditingController();
  final unitsController = TextEditingController();
  final mayoreoController = TextEditingController();
  final mayoreoUnitsController = TextEditingController();
  final barcodeController = TextEditingController();

  // Package Controllers
  final packageUnitsController = TextEditingController();
  final packageSearchController = TextEditingController();
  TextEditingController? _internalPackageSearchController;
  List<Map<String, dynamic>> selectedPackageProducts = [];
  double suggestedPackagePrice = 0.0;

  bool isBulk = false;
  bool hasMayoreo = false;
  bool isLoading = false;
  bool isPackage = false;
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
    "General",
    "Otros",
   
  ];

  @override
  void initState() {
    super.initState();
   
    
    nameController.text = widget.product['name']?.toString() ?? '';
    barcodeController.text = (widget.product['barcode'] ?? '').toString();
    unitsController.text = (widget.product['units'] ?? 0).toString();
    packageUnitsController.text = (widget.product['units'] ?? 0).toString();
    purchasePriceController.text = (widget.product['buyingPrice'] ?? 0).toString();
    salePriceController.text = (widget.product['sellingPrice'] ?? 0).toString();
    weightController.text = (widget.product['weight'] ?? 0).toString();
    selectedCategory = widget.product['category']?.toString() ?? 'Sin categoría';
    mayoreoController.text = (widget.product['wholesalePrice'] ?? 0).toString();
    mayoreoUnitsController.text = (widget.product['wholesaleMinUnits'] ?? 0).toString();
    isBulk = widget.product['isBulk'] ?? false;
    hasMayoreo = widget.product['hasWholesalePrice'] ?? false;
    isPackage = widget.product['isPackage'] ?? false;

    //print(widget.product); 

    if (isPackage) {
      final packageContents = widget.product['packageContents'] as List<dynamic>?;
      if (packageContents != null) {
        selectedPackageProducts = List<Map<String, dynamic>>.from(
          packageContents.map((c) => Map<String, dynamic>.from(c))
        );
        _calculateSuggestedPrice();
      }
    }
  }

  void _calculateSuggestedPrice() {
    double total = 0;
    for (var p in selectedPackageProducts) {
      final price = (p['product']['sellingPrice'] as num?)?.toDouble() ?? 0.0;
      final qty = (p['quantity'] as num?)?.toDouble() ?? 1.0;
      total += price * qty;
    }
    setState(() {
      suggestedPackagePrice = total;
    });
  }

  Future<void> updateProduct() async {
    if (isLoading) return;
    final id = widget.product['_id']?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID inválido')));
      return;
    }
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el nombre')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    // double totalBuyingPrice = 0;
    // if (isPackage) {
    //   for (var p in selectedPackageProducts) {
    //     totalBuyingPrice += ((p['buyingPrice'] as num?)?.toDouble() ?? 0.0) * (p['quantity'] ?? 1);
    //   }
    // }

    final result = await InventoryService.updateProduct(
      id: id,
      name: nameController.text.trim(),
      barcode: barcodeController.text,
      isBulk: isPackage ? false : isBulk,
      weight: isPackage ? 1.0 : (double.tryParse(weightController.text) ?? 0.0),
      category: isPackage ? 'Paquetes' : selectedCategory,
      units: double.tryParse(isPackage ? packageUnitsController.text : unitsController.text) ?? 0,
      buyingPrice:  (double.tryParse(purchasePriceController.text.replaceAll(",", "")) ?? 0.0),
      sellingPrice: double.tryParse(salePriceController.text.replaceAll(",", "")) ?? 0.0,
      bulkPrice: isPackage ? 0.0 : (double.tryParse(weightController.text) ?? 0.0),
      hasWholesalePrice: isPackage ? false : hasMayoreo,
      wholesalePrice: isPackage ? 0.0 : (double.tryParse(mayoreoController.text.replaceAll(",", "")) ?? 0.0),
      wholesaleMinUnits: isPackage ? 0 : (int.tryParse(mayoreoUnitsController.text) ?? 0),
      packageContents: isPackage ? selectedPackageProducts.map((p) => {
        'product': p['product']['_id'] ,
        'quantity': p['quantity'],
      }).toList() : null,
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
  void dispose() {
    nameController.dispose();
    purchasePriceController.dispose();
    salePriceController.dispose();
    weightController.dispose();
    unitsController.dispose();
    mayoreoController.dispose();
    mayoreoUnitsController.dispose();
    barcodeController.dispose();
    packageUnitsController.dispose();
    packageSearchController.dispose();
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
          updateProduct();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        isPackage ? 'Editar Paquete' : 'Editar Producto',
        style: GoogleFonts.poppins(
          color: Theme.of(context).colorScheme.onSurface,
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
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  controller: nameController,
                  decoration: _inputDecoration(context, labelText: isPackage ? 'Nombre del Paquete' : 'Nombre del Producto'),
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 24),

                if (isPackage) ...[
                  // UI DE PAQUETE
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
                            // final pWithQty = Map<String, dynamic>.from(product);
                            // pWithQty['quantity'] = 1;
                            // selectedPackageProducts.add(pWithQty);

                             selectedPackageProducts.add({
                              'product': product,
                              'quantity': 1,
                            });
                            _calculateSuggestedPrice();
                            salePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
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
                  const SizedBox(height: 24),
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
                              final stock = (p['product']['units'] ?? 0);
                              final qty = p['quantity'] ?? 1;


                              print(p); 

                              return ListTile(
                                title: Text(p['product']['name'] ?? '', style: GoogleFonts.poppins(fontSize: 14)),
                                subtitle: Text('Estado: ${stock == 0 ? "Sin Stock" : stock < 5 ? "Bajo Stock ($stock)" : "En Stock ($stock)"}', 
                                  style: GoogleFonts.poppins(fontSize: 11, color: stock == 0 ? Colors.red : stock < 5 ? Colors.orange : Colors.green)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: qty > 1 ? () {
                                        setState(() {
                                          p['quantity'] = qty - 1;
                                          _calculateSuggestedPrice();
                                          salePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                        });
                                      } : null,
                                    ),
                                    Text('$qty', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () {
                                        setState(() {
                                          p['quantity'] = qty + 1;
                                          _calculateSuggestedPrice();
                                          salePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                        });
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Text(CurrencyFormatter.format(((p['product']['sellingPrice'] as num?)?.toDouble() ?? 0.0) * qty), 
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: const Color(0xFF05e265))),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          selectedPackageProducts.removeAt(index);
                                          _calculateSuggestedPrice();
                                          salePriceController.text = suggestedPackagePrice.toStringAsFixed(2);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: salePriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: _inputDecoration(context, labelText: 'Precio Final del Paquete', prefixText: r'$ '),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: packageUnitsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration(context, labelText: 'Stock del Paquete'),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ] else ...[
                  // UI DE PRODUCTO NORMAL
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
                  TextField(
                    controller: unitsController,
                    keyboardType: TextInputType.numberWithOptions(decimal: isBulk),
                    inputFormatters: isBulk
                        ? [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))]
                        : [FilteringTextInputFormatter.digitsOnly],
                    decoration: _inputDecoration(context, labelText: isBulk ? 'KG CT' : 'Unidades'),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                    const SizedBox(height: 24),
                  ],
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
            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
          ),
        ),
        ElevatedButton(
          onPressed: isLoading ? null : updateProduct,
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
                  'Actualizar',
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
