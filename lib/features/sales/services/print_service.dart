import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sales_models.dart';
import 'package:http/http.dart' as http;

class PrintService {
  static Future<void> printTicket({
    required String businessName,
    required List<CartItem> items,
    required double total,
    required double received,
    required double change,
    required String paymentMethod,
    String? address,
    String? phone,
    String? userLogoUrl, 
  }) async {
    final doc = pw.Document();


  Uint8List? logoBytes;
  if (userLogoUrl != null && userLogoUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(userLogoUrl));
      if (response.statusCode == 200) {
        logoBytes = response.bodyBytes;
      } else {
        logoBytes = null; // No se pudo cargar
      }
    } catch (e) {
      logoBytes = null; // Error de red
    }
  }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Estándar para tickets de 80mm
        margin: const pw.EdgeInsets.all(2 * PdfPageFormat.mm), // Márgenes mínimos
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min, // Que use el mínimo espacio vertical posible
            children: [
              // Encabezado
              pw.Center(
                child: pw.Column(
                  children: [
                     if (logoBytes != null)
                      pw.Center(
                          child: pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 50,
                            height: 50,
                            fit: pw.BoxFit.contain,
                          
                          ),
                      ), 
                    if (logoBytes != null) pw.SizedBox(height: 4),
                    pw.Text(
                      businessName,
                      style:  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text('FECHA: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 8)),
                    pw.Divider(thickness: 0.5, height: 4),
                  ],
                ),
              ),

              // Lista de productos sin padding extra
              ...items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text('${item.quantity.toStringAsFixed(item.isBulk ? 3 : 0)} ${item.name}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                );
              }).toList(),
              pw.Divider(thickness: 0.5, height: 4),

              // Totales más compactos
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL VENTA:',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MÉTODO DE PAGO:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(paymentMethod.toUpperCase(), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EFECTIVO RECIBIDO:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text('\$${received.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SU CAMBIO:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${change.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text('¡Gracias por su preferencia!',
                    style: const pw.TextStyle(fontSize: 8)),
              ),
            ],
          );
        },
      ),
    );

    // Esto abre el diálogo del sistema. El usuario puede elegir la impresora Epson
    // o guardar como PDF si no hay impresora conectada.
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) => doc.save(),
      name: 'ticket_venta_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }
}
