

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class WebBarcodeScanner extends StatefulWidget {
  final Function(String) onScanned;

  const WebBarcodeScanner({super.key, required this.onScanned});

  @override
  State<WebBarcodeScanner> createState() => _WebBarcodeScannerState();
}

class _WebBarcodeScannerState extends State<WebBarcodeScanner> {
  late MobileScannerController controller;
  
  // Definimos el tamaño del cuadro de escaneo
  final double scanAreaSize = 200.0;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
      cameraResolution: const Size(1920, 1080),
      detectionSpeed: DetectionSpeed.normal,
      
      
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Calculamos el centro exacto para el scanWindow
      final Rect scanWindow = Rect.fromCenter(
        center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
        width: scanAreaSize,
        height: scanAreaSize,
      );

      return Stack(
        children: [
          // 1. El Scanner de fondo
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            scanWindow: Rect.fromCenter(
              center: Offset(MediaQuery.of(context).size.width / 2, 175), // Ajustado a tu modal de 350
              width: 200,
              height: 200,
            ),
      
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                widget.onScanned(barcode.rawValue!);
              }
            },
          ),

          // 2. El Rectángulo Verde Centrado
          Center(
            child: Container(
              width: scanAreaSize,
              height: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // 3. Efecto de "Oscurecimiento" fuera del área (Opcional pero recomendado)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 4. Texto de ayuda
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              "Coloca el código dentro del recuadro",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    });
  }
}