import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';


class BarcodeScannerModal extends StatefulWidget {
  const BarcodeScannerModal({super.key});

  @override
  State<BarcodeScannerModal> createState() => _BarcodeScannerModalState();
}

class _BarcodeScannerModalState extends State<BarcodeScannerModal> {
  bool scanned = false;
  late MobileScannerController controller;

 @override
  void initState() {
    super.initState();

    if (!kIsWeb) {
      controller = MobileScannerController(
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      controller.dispose();
    }
    super.dispose();
  }

  



  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: Container(
        height: 350,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        child: kIsWeb
            ? _buildWebNotSupported()
            : _buildMobileScanner(),
      ),
    );
  }


  Widget _buildWebNotSupported() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white54,
                  size: 60,
                ),
                SizedBox(height: 20),
                Text(
                  "El escáner no está soportado en la versión web.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }


  Widget _buildMobileScanner() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (scanned) return;

              final barcode = capture.barcodes.first;
              final String? code = barcode.rawValue;
              if (code == null) return;

              scanned = true;

              HapticFeedback.mediumImpact();

              Navigator.pop(context, code);
            },
          ),
        ),
        Center(
          child: Container(
            width: 220,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }




}


