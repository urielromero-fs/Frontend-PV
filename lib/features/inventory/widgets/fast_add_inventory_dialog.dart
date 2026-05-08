import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/inventory_service.dart';
import '../providers/product_provider.dart';

class FastAddInventoryDialog extends StatefulWidget {
  final String? branchId;

  const FastAddInventoryDialog({super.key, this.branchId});

  @override
  State<FastAddInventoryDialog> createState() => _FastAddInventoryDialogState();
}

class _FastAddInventoryDialogState extends State<FastAddInventoryDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _unitsController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _unitsFocusNode = FocusNode();

  Map<String, dynamic>? _selectedProduct;
  List<dynamic> _searchResults = [];
  bool _isSaving = false;
  String _errorMessage = '';

  // For barcode scanner
  String _barcodeBuffer = '';
  DateTime _lastKeyEventTime = DateTime.now();
  final FocusNode _keyboardFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-focus the search field when the dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _unitsController.dispose();
    _searchFocusNode.dispose();
    _unitsFocusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final now = DateTime.now();
    final character = event.character;

    if (character == null || character.isEmpty) return;

    if (!_searchFocusNode.hasFocus && !_unitsFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }

    final diff = now.difference(_lastKeyEventTime).inMilliseconds;
    _lastKeyEventTime = now;

    if (diff > 100) {
      // Normal typing
      return;
    }

    // Scanner
    _barcodeBuffer += character;

    if (event.logicalKey == LogicalKeyboardKey.enter && _barcodeBuffer.isNotEmpty) {
      _searchController.text = _barcodeBuffer;
      _searchProduct(_barcodeBuffer);
      _barcodeBuffer = '';
    }
  }

  void _searchProduct(String query) {
    setState(() {
      _errorMessage = '';
      _searchResults = [];
    });
    
    final queryLower = query.trim().toLowerCase();
    if (queryLower.isEmpty) {
      setState(() {
        _selectedProduct = null;
      });
      return;
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);
    final allProducts = provider.allProducts;

    final matches = allProducts.where(
      (p) {
        final barcode = (p['barcode'] ?? '').toString().toLowerCase();
        final name = (p['name'] ?? '').toString().toLowerCase();
        return barcode == queryLower || name.contains(queryLower);
      },
    ).toList();

    if (matches.isEmpty) {
      setState(() {
        _selectedProduct = null;
        _errorMessage = 'Producto no encontrado';
      });
    } else if (matches.length == 1) {
      _selectProduct(matches.first);
    } else {
      setState(() {
        _selectedProduct = null;
        _searchResults = matches;
      });
    }
  }

  void _selectProduct(dynamic product) {
    setState(() {
      _selectedProduct = product;
      _searchResults = [];
      _unitsController.clear();
    });
    
    // Give focus to units input
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _unitsFocusNode.requestFocus();
      }
    });
  }

  Future<void> _saveStock() async {
    if (_isSaving || _selectedProduct == null) return;
    
    final String val = _unitsController.text.trim();
    if (val.isEmpty) return;
    
    final double addUnits = double.tryParse(val) ?? 0;
    if (addUnits <= 0) return;

    setState(() => _isSaving = true);
    
    final double currentUnits = double.tryParse(_selectedProduct!['units']?.toString() ?? '0') ?? 0;
    final double newUnits = currentUnits + addUnits;

    final result = await InventoryService.updateProduct(
      id: _selectedProduct!['_id'],
      name: _selectedProduct!['name'],
      barcode: _selectedProduct!['barcode'] ?? 'N/A',
      isBulk: _selectedProduct!['isBulk'] ?? false,
      weight: (_selectedProduct!['weight'] ?? 0.0).toDouble(),
      category: _selectedProduct!['category'] ?? 'Sin categoría',
      units: newUnits,
      buyingPrice: (_selectedProduct!['buyingPrice'] ?? 0.0).toDouble(),
      sellingPrice: (_selectedProduct!['sellingPrice'] ?? 0.0).toDouble(),
      bulkPrice: (_selectedProduct!['bulkPrice'] ?? 0.0).toDouble(),
      hasWholesalePrice: _selectedProduct!['hasWholesalePrice'] ?? false,
      wholesalePrice: (_selectedProduct!['wholesalePrice'] ?? 0.0).toDouble(),
      wholesaleMinUnits: _selectedProduct!['wholesaleMinUnits'] ?? 0,
    );

    if (mounted) {
      if (result['success']) {
        // Show success alert in front of the modal
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            });
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: const Color(0xFF05e265),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '¡Agregado!',
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          },
        );
        
        // Refresh provider
        Provider.of<ProductProvider>(context, listen: false).fetchProducts(branchId: widget.branchId);

        // Reset state for next scan/search
        setState(() {
          _isSaving = false;
          _selectedProduct = null;
          _searchResults = [];
          _searchController.clear();
          _unitsController.clear();
        });
        
        // Focus back to search
        _searchFocusNode.requestFocus();
      } else {
        setState(() => _isSaving = false);
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
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Agregar Inventario Rápido',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Buscar por nombre o código de barras',
                  labelStyle: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF05e265)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                onSubmitted: _searchProduct,
                textInputAction: TextInputAction.search,
              ),
              
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(color: Colors.red, fontSize: 13),
                ),
              ],
              
              const SizedBox(height: 24),
              
              if (_searchResults.isNotEmpty) ...[
                Text(
                  'Múltiples resultados (${_searchResults.length}):',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(color: Theme.of(context).dividerColor.withOpacity(0.2), height: 1),
                    itemBuilder: (context, index) {
                      final p = _searchResults[index];
                      return ListTile(
                        title: Text(
                          p['name'] ?? 'Sin nombre',
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Stock: ${p['units']} ${p['isBulk'] == true ? 'Kg CT' : 'Unidades'}',
                          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                        ),
                        onTap: () => _selectProduct(p),
                      );
                    },
                  ),
                ),
              ] else if (_selectedProduct != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Producto encontrado:',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedProduct!['name'] ?? 'Sin nombre',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stock actual: ${_selectedProduct!['units']} ${_selectedProduct!['isBulk'] == true ? 'Kg CT' : 'Unidades'}',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _unitsController,
                  focusNode: _unitsFocusNode,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Unidades a agregar',
                    labelStyle: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF05e265)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  onSubmitted: (_) => _saveStock(),
                  textInputAction: TextInputAction.done,
                ),
              ] else if (_errorMessage.isEmpty) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      'Busca o escanea un producto para continuar',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          if (_selectedProduct != null)
            ElevatedButton(
              onPressed: _isSaving ? null : _saveStock,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
                disabledBackgroundColor: Colors.grey.withOpacity(0.3),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Guardar',
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
