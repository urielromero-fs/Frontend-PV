import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pv26/core/utils/currency_formatter.dart';
import '../models/sales_models.dart';
import 'qty_btn.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem item;
  final Function(double) onQuantityChanged;
  final VoidCallback onRemove;
  const CartItemWidget({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) {
    // Determine quantity display format
    String quantityText = item.isBulk
        ? '${item.quantity.toStringAsFixed(3)} KG'
        : item.quantity.toInt().toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Info
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  item.isBulk
                      ? '${CurrencyFormatter.format(item.price)} / kg'
                      : '${CurrencyFormatter.format(item.price)} c/u',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Quantity Controls
          Row(
            children: [
              QtyBtn(
                icon: Icons.remove,
                onTap: () =>
                    onQuantityChanged(item.quantity - (item.isBulk ? 0.1 : 1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  quantityText,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              QtyBtn(
                icon: Icons.add, 
                onTap: () => onQuantityChanged(item.quantity + (item.isBulk ? 0.1 : 1)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Item Total
          Expanded(
            flex: 2,
            child: Text(
              CurrencyFormatter.format(item.price * item.quantity),
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: const Color(0xFF05e265),
                fontSize: 19, // Aumentado de 16 a 19
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8), // Separación del botón de eliminar
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.withAlpha(200), size: 20),
            onPressed: onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
