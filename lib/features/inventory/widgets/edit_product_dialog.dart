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
    "General",
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
    mayoreoUnitsController.text = (widget.product['wholesaleMinUnits'] ?? 0).toString();
    isBulk = widget.product['isBulk'] ?? false;
    hasMayoreo = widget.product['hasWholesalePrice'] ?? false;
  }

  Future<void> updateProduct() async {
    if (isLoading) return;
    final id = widget.product['_id']?.toString() ?? '';
    if (id.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ID inválido')));
      return;
    }
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ingresa el nombre')));
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
    if (result['success'] == true) {
      widget.onProductUpdated();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error al actualizar')),
      );
    }
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
        'Actualizar Producto',
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
                    onSubmitted: (_) => updateProduct(),
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
                        onSubmitted: (_) => updateProduct(),
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
                  decoration: _inputDecoration(context, labelText: 'Categoría'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: unitsController,
                  onSubmitted: (_) => updateProduct(),
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
                  onSubmitted: (_) => updateProduct(),
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
                  onSubmitted: (_) => updateProduct(),
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
                          onSubmitted: (_) => updateProduct(),
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
                          onSubmitted: (_) => updateProduct(),
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    ));
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
