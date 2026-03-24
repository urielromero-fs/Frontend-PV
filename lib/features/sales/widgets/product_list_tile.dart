import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pv26/core/utils/currency_formatter.dart';

class ProductListTile extends StatelessWidget {
  final String name;
  final double price;
  final bool isBulk;
  final double units;
  final double remainingUnits;
  final VoidCallback onTap;
  final VoidCallback onAddStock;

  const ProductListTile({
    super.key,
    required this.name,
    required this.price,
    required this.isBulk,
    required this.units,
    required this.remainingUnits,
    required this.onTap,
    required this.onAddStock,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasStock = remainingUnits > 0;
    return GestureDetector(
      onTap: hasStock ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(hasStock ? 1.0 : 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasStock 
                ? Theme.of(context).dividerColor.withOpacity(0.1) 
                : Colors.red.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon / Indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (hasStock ? const Color(0xFF05e265) : Colors.red).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isBulk ? Icons.scale : Icons.inventory_2,
                color: hasStock ? const Color(0xFF05e265) : Colors.redAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Opacity(
                opacity: hasStock ? 1.0 : 0.5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          CurrencyFormatter.format(price),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF05e265),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (isBulk) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.orange.withOpacity(0.5)),
                            ),
                            child: Text(
                              'Granel',
                              style: GoogleFonts.poppins(
                                color: Colors.orange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Stock Status / Add Stock Button
            if (!hasStock) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'SIN STOCK',
                  style: GoogleFonts.poppins(
                    color: Colors.redAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onAddStock,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05e265).withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF05e265).withAlpha(100)),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF05e265),
                    size: 18,
                  ),
                ),
              ),
            ] else 
              Icon(
                Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
