import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/inventory_service.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Inventario',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductModal(context);
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
              // Search and Filter
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
                        decoration: InputDecoration(
                          hintText: 'Buscar productos...',
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

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Total Productos',
                      value: '248',
                      icon: Icons.inventory,
                      color: const Color(0xFF05e265),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Bajo Stock',
                      value: '12',
                      icon: Icons.warning,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      title: 'Sin Stock',
                      value: '3',
                      icon: Icons.error,
                      color: const Color(0xFFE91E63),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Products Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withAlpha(26)),
                  ),
                  child: Column(
                    children: [
                      // Table Header
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
                              child: Text(
                                'Estado',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white24),
                      
                      // Sample Products
                      Expanded(
                        child: ListView.builder(
                          itemCount: 10,
                          itemBuilder: (context, index) {
                            return _ProductRow(
                              name: 'Producto ${index + 1}',
                              category: 'Categoría ${index % 3 + 1}',
                              stock: '${(index + 1) * 5}',
                              price: '\$${(index + 1) * 25.50}',
                              status: index % 5 == 0 ? 'Sin Stock' : 
                                       index % 3 == 0 ? 'Bajo Stock' : 'En Stock',
                              statusColor: index % 5 == 0 ? const Color(0xFFE91E63) :
                                           index % 3 == 0 ? const Color(0xFFFF9800) : const Color(0xFF05e265),
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
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

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
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final String category;
  final String stock;
  final String price;
  final String status;
  final Color statusColor;

  const _ProductRow({
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(26)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.poppins(
                color: Colors.white70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              stock,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              price,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(51),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAddProductModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          final nameController = TextEditingController();
          final purchasePriceController = TextEditingController();
          final salePriceController = TextEditingController();
          final weightController = TextEditingController();
          final unitsController = TextEditingController();
          final mayoreoController = TextEditingController();
          final barcodeController = TextEditingController();
          bool isBulk = false;
          bool hasMayoreo = false;
          bool isLoading = false;

          Future<void> saveProduct() async {
            // Get form values from the modal
            final name = nameController.text.trim();
            final barcode = barcodeController.text.trim();
            final isBulkValue = isBulk;
            final units = int.tryParse(unitsController.text) ?? 0;
            final buyingPrice = double.tryParse(purchasePriceController.text) ?? 0.0;
            final sellingPrice = double.tryParse(salePriceController.text) ?? 0.0;
            final bulkPrice = double.tryParse(weightController.text) ?? 0.0;
            final hasWholesalePrice = hasMayoreo;
            final wholesalePrice = double.tryParse(mayoreoController.text) ?? 0.0;

            // Validate required fields
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Por favor ingresa el nombre del producto',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            // Set loading state
            setState(() {
              isLoading = true;
            });

            // Make API call
            final result = await InventoryService.createProduct(
              name: name,
              barcode: barcode.isEmpty ? 'N/A' : barcode,
              isBulk: isBulkValue,
              units: units,
              buyingPrice: buyingPrice,
              sellingPrice: sellingPrice,
              bulkPrice: bulkPrice,
              hasWholesalePrice: hasWholesalePrice,
              wholesalePrice: wholesalePrice,
            );

            // Set loading to false
            setState(() {
              isLoading = false;
            });

            // Show result
            if (context.mounted) {
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Producto creado exitosamente',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: const Color(0xFF05e265),
                    duration: const Duration(seconds: 3),
                  ),
                );
                
                // Close dialog after success
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result['message'] ?? 'Error al crear producto',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          }
          return AlertDialog(
            backgroundColor: const Color(0xFF1a1a1a),
            title: Text(
              'Agregar Producto',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product Name
                  TextField(
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
                            _scanBarcode(context);
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
                      keyboardType: TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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

                  // Units (always shown)
                  TextField(
                    controller: unitsController,
                    keyboardType: TextInputType.numberWithOptions(decimal: false),
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
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
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

                  // Mayoreo Price (conditional)
                  if (hasMayoreo) ...[
                    TextField(
                      controller: mayoreoController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Guardar',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

void _scanBarcode(BuildContext context) {
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
