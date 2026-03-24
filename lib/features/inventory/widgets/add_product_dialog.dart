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

class _AddProductDialogState extends State<AddProductDialog> {
  final nameController = TextEditingController();
  final purchasePriceController = TextEditingController();
  final salePriceController = TextEditingController();
  final weightController = TextEditingController();
  final unitsController = TextEditingController();
  final mayoreoController = TextEditingController();
  final mayoreoUnitsController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          saveProduct();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      title: Text(
        'Añadir Producto',
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
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: TextField(
                    autofocus: true,
                    controller: nameController,
                    onSubmitted: (_) => saveProduct(),
                    decoration: InputDecoration(
                      labelText: 'Nombre del Producto',
                      labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                      floatingLabelStyle: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF05e265)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        onSubmitted: (_) => saveProduct(),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'CB (Código de Barras)',
                          labelStyle: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF05e265),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _scanBarcodeWithOptions(context, barcodeController);
                        },
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
                if (isBulk) ...[const SizedBox(height: 16)],
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
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitsController,
                  onSubmitted: (_) => saveProduct(),
                  keyboardType: TextInputType.numberWithOptions(
                      decimal: isBulk,
                    ),
                  inputFormatters: isBulk
                        ? [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ]
                        : [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                  decoration: InputDecoration(
                    labelText: isBulk ? 'KG CT' : 'Unidades',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: purchasePriceController,
                  onSubmitted: (_) => saveProduct(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    prefixText: r'$ ',
                    prefixStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    labelText: isBulk
                        ? 'Precio de Compra (por 1 KG CT)'
                        : 'Precio de Compra',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: salePriceController,
                  onSubmitted: (_) => saveProduct(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: InputDecoration(
                    prefixText: r'$ ',
                    prefixStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                    labelText: isBulk
                        ? 'Precio de Venta (por 1 KG CT)'
                        : 'Precio de Venta',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                          onSubmitted: (_) => saveProduct(),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: InputDecoration(
                            prefixText: r'$ ',
                            prefixStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                            labelText: 'Precio Mayoreo',
                            labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF05e265)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: mayoreoUnitsController,
                          onSubmitted: (_) => saveProduct(),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            labelText: 'Mínimo Unidades',
                            labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFF05e265)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
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
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Añadir',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
