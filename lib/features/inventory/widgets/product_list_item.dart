import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';





class ProductListItem extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final String stock;
  final String price;
  final String status;
  final Color statusColor;
  final String userRole;
  final bool isBulk;
  final bool hasWholesalePrice;
  final String wholesalePrice;
  final int wholesaleMinUnits;
  //Acciones
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onAddStock;


  const ProductListItem({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.stock,
    required this.status,
    required this.statusColor,
    required this.userRole,
    required this.isBulk,
    required this.onDelete,
    required this.onEdit,
    required this.onAddStock,
    required this.price,
    required this.hasWholesalePrice,
    required this.wholesalePrice,
    required this.wholesaleMinUnits,

  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;



   
      Widget actionButton = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF05e265).withAlpha(26),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF05e265).withAlpha(51),
            width: 1,
          ),
        ),
        child: const Icon(Icons.more_vert, color: Color(0xFF05e265), size: 20),
      );


      Widget addStockButton = GestureDetector(
          onTap: onAddStock,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
            color: const Color(0xFF05e265).withAlpha(40),
            borderRadius: BorderRadius.circular(4),
              ),
            child: const Icon(
                      Icons.add,
                      color: Color(0xFF05e265),
                      size: 18,
                    ),
            ),
        ); 

  


    final actionsMenu = PopupMenuButton<String>(

      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },

      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF05e265), size: 20),
              const SizedBox(width: 12),
              Text(
                'Editar',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),

        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Color(0xFFE91E63), size: 20),
              const SizedBox(width: 12),
              Text(
                'Eliminar',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
      ],


       child: actionButton, 
  

    );

    

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
                if (userRole == 'admin' || userRole == 'administrador' || userRole == 'master') ...[
                  const SizedBox(width: 8),
                  actionsMenu,
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '${isBulk ? 'KG CT' : 'Stock'}: $stock',
                      style: GoogleFonts.poppins(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: onAddStock,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF05e265).withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF05e265),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF05e265),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (hasWholesalePrice) ...[
              const SizedBox(height: 8),
              Text(
                'Mayoreo: $wholesalePrice (desde $wholesaleMinUnits uds)',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF05e265).withAlpha(200),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              category,
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  '$stock ${isBulk ? 'Kg CT' : 'Uds'}',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),



                addStockButton,




              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasWholesalePrice)
                  Text(
                    'Mayoreo: $wholesalePrice ($wholesaleMinUnits+)',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF05e265),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
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
          ),
          if (userRole == 'admin' || userRole == 'administrador'  || userRole == 'master')
            Expanded(child: Center(child: actionsMenu))
          else
            const Spacer(),
        ],
      ),
    );
  }
}
