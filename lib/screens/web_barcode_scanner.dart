import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WebBarcodeScanner extends StatefulWidget {
  final Function(String) onScanned;

  const WebBarcodeScanner({super.key, required this.onScanned});

  @override
  State<WebBarcodeScanner> createState() => _WebBarcodeScannerState();
}

class _WebBarcodeScannerState extends State<WebBarcodeScanner> {
  // Usamos el mismo controlador que en móvil
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal, // Evita procesar demasiados frames por segundo
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              // Detenemos el scanner un momento para evitar múltiples pops
              controller.stop(); 
              widget.onScanned(code);
            }
          }
        },
      ),
    );
  }
}