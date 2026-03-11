import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/sales_models.dart';

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
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Estándar para tickets de 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('FECHA: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Divider(thickness: 0.5),
                  ],
                ),
              ),

              // Lista de productos
              ...items.map((item) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 1),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text('${item.quantity.toStringAsFixed(item.isBulk ? 3 : 0)} ${item.name}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Text('\$${(item.price * item.quantity).toStringAsFixed(2)}',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
              pw.Divider(thickness: 0.5),

              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('TOTAL VENTA:',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${total.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('MÉTODO DE PAGO:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text(paymentMethod.toUpperCase(), style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('EFECTIVO RECIBIDO:', style: const pw.TextStyle(fontSize: 9)),
                  pw.Text('\$${received.toStringAsFixed(2)}',
                      style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('SU CAMBIO:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('\$${change.toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.SizedBox(height: 15),
              pw.Center(
                child: pw.Text('¡Gracias por su preferencia!',
                    style: const pw.TextStyle(fontSize: 9)),
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
