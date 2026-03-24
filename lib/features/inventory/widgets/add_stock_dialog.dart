import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';

class AddStockDialog extends StatefulWidget {
  final Map product;
  final VoidCallback onSaved;

  const AddStockDialog({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  State<AddStockDialog> createState() => _AddStockDialogState();
}

class _AddStockDialogState extends State<AddStockDialog> {
  final TextEditingController stockController = TextEditingController();
  bool isSaving = false;

  Future<void> saveStock() async {
    if (isSaving) return;
    final String val = stockController.text.trim();
    if (val.isEmpty) return;
    
    final double addUnits = double.tryParse(val) ?? 0;
    if (addUnits <= 0) return;

    setState(() => isSaving = true);
    
    final double currentUnits = double.tryParse(widget.product['units']?.toString() ?? '0') ?? 0;
    final double newUnits = currentUnits + addUnits;

    final result = await InventoryService.updateProduct(
      id: widget.product['_id'],
      name: widget.product['name'],
      barcode: widget.product['barcode'] ?? 'N/A',
      isBulk: widget.product['isBulk'] ?? false,
      weight: (widget.product['weight'] ?? 0.0).toDouble(),
      category: widget.product['category'] ?? 'Sin categoría',
      units: newUnits,
      buyingPrice: (widget.product['buyingPrice'] ?? 0.0).toDouble(),
      sellingPrice: (widget.product['sellingPrice'] ?? 0.0).toDouble(),
      bulkPrice: (widget.product['bulkPrice'] ?? 0.0).toDouble(),
      hasWholesalePrice: widget.product['hasWholesalePrice'] ?? false,
      wholesalePrice: (widget.product['wholesalePrice'] ?? 0.0).toDouble(),
      wholesaleMinUnits: widget.product['wholesaleMinUnits'] ?? 0,
    );

    if (mounted) {
      if (result['success']) {
        widget.onSaved();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock actualizado correctamente'),
            backgroundColor: Color(0xFF05e265),
          ),
        );
      } else {
        setState(() => isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al actualizar stock'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
          saveStock();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Agregar Stock',
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
              'Producto: ${widget.product['name']}',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Stock actual: ${widget.product['units']} ${widget.product['isBulk'] == true ? 'Kg CT' : 'Unidades'}',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: stockController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
              onSubmitted: (_) => saveStock(),
              decoration: InputDecoration(
                labelText: 'Cantidad a agregar',
                labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
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
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54)),
            ),
          ),
          ElevatedButton(
            onPressed: isSaving ? null : saveStock,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05e265),
              disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            ),
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text(
                    'Agregar',
                    style: GoogleFonts.poppins(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
