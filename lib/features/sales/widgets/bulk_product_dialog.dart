import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pv26/core/utils/currency_formatter.dart';

class BulkProductDialog extends StatefulWidget {
  final String productName;
  final double pricePerKg;
  const BulkProductDialog({
    super.key,
    required this.productName,
    required this.pricePerKg,
  });
  @override
  State<BulkProductDialog> createState() => _BulkProductDialogState();
}
class _BulkProductDialogState extends State<BulkProductDialog> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _amountFocus = FocusNode();
  bool _isUpdating = false;
  @override
  void initState() {
    super.initState();
    _weightController.addListener(_onWeightChanged);
    _amountController.addListener(_onAmountChanged);
  }
  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _amountController.removeListener(_onAmountChanged);
    _weightController.dispose();
    _amountController.dispose();
    _weightFocus.dispose();
    _amountFocus.dispose();
    super.dispose();
  }
  void _onWeightChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final text = _weightController.text;
    if (text.isEmpty) {
      _amountController.clear();
    } else {
      final val = double.tryParse(text) ?? 0.0;
      final total = val * widget.pricePerKg;
      final formatter = NumberFormat("#,###.00", "en_US");
      _amountController.text = formatter.format(total);
    }
    _isUpdating = false;
  }
  void _onAmountChanged() {
    if (_isUpdating) return;
    _isUpdating = true;
    final text = _amountController.text.replaceAll(",", "");
    if (text.isEmpty) {
      _weightController.clear();
    } else {
      final val = double.tryParse(text) ?? 0.0;
      _weightController.text = (val / widget.pricePerKg).toStringAsFixed(3);
    }
    _isUpdating = false;
  }
  void _submit() {
    final qty = double.tryParse(_weightController.text);
    if (qty != null && qty >= 0) {
      Navigator.pop(context, {
        'type': 0.0,
        'value': qty,
      });
    }
  }
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
          event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_weightFocus.hasFocus) {
          _amountFocus.requestFocus();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                 event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_amountFocus.hasFocus) {
          _weightFocus.requestFocus();
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1a1a1a),
      title: Text(
        widget.productName,
        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      content: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: _handleKeyEvent,
        child: SizedBox( // Replaced Container with SizedBox
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Row(
              children: [
                // Weight Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Peso (Kg)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        focusNode: _weightFocus,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,3}')),
                        ],
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.000',
                          hintStyle: GoogleFonts.poppins(color: Colors.white12),
                          suffixText: 'Kg',
                          suffixStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF02e3b2), width: 1.5)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Icon in middle
                const Icon(Icons.sync, color: Colors.white24, size: 20),
                const SizedBox(width: 16),
                // Price/Amount Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto (\$)', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountController,
                        focusNode: _amountFocus,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [CurrencyInputFormatter()],
                        style: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 22, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: GoogleFonts.poppins(color: Colors.white12),
                          prefixText: r'$ ',
                          prefixStyle: GoogleFonts.poppins(color: const Color(0xFF05e265), fontSize: 20),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF05e265), width: 1.5)),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
              'Precio por Kg: ${CurrencyFormatter.format(widget.pricePerKg)}',
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: GoogleFonts.poppins(color: Colors.white54),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF05e265),
          ),
          child: Text(
            'Agregar',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
