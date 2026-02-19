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

  bool showOptions = true; // <- controla si mostramos selector
  bool useHardwareScanner = false;

  final FocusNode _hardwareFocusNode = FocusNode();
  final TextEditingController _hardwareController = TextEditingController();

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
    _hardwareFocusNode.dispose();
    _hardwareController.dispose();
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
        child: showOptions
            ? _buildOptions()
            : useHardwareScanner
                ? _buildHardwareScanner()
                : kIsWeb
                    ? _buildWebNotSupported()
                    : _buildMobileScanner(),
      ),
    );
  }

  // ===============================
  // SELECTOR DE OPCIONES
  // ===============================
  Widget _buildOptions() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Selecciona método de escaneo",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _optionButton(
                      icon: Icons.camera_alt,
                      label: "Cámara",
                      onTap: () {
                        setState(() {
                          showOptions = false;
                          useHardwareScanner = false;
                        });
                      },
                    ),
                    _optionButton(
                      icon: Icons.qr_code_scanner,
                      label: "Scanner Físico",
                      onTap: () {
                        setState(() {
                          showOptions = false;
                          useHardwareScanner = true;
                        });

                        Future.delayed(const Duration(milliseconds: 200), () {
                          _hardwareFocusNode.requestFocus();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _closeButton(),
      ],
    );
  }

  Widget _optionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.greenAccent, size: 32),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  // ===============================
  // HARDWARE SCANNER
  // ===============================
  Widget _buildHardwareScanner() {
    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Escanea con el dispositivo físico",
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 20),
                TextField(
                  focusNode: _hardwareFocusNode,
                  controller: _hardwareController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Esperando escaneo...",
                    hintStyle: TextStyle(color: Colors.white54),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      Navigator.pop(context, value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        _closeButton(),
      ],
    );
  }

  // ===============================
  // MOBILE CAMERA
  // ===============================
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
              final code = barcode.rawValue;
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
        _closeButton(),
      ],
    );
  }

  // ===============================
  // WEB
  // ===============================
  Widget _buildWebNotSupported() {
    return Stack(
      children: [
        const Center(
          child: Text(
            "No soportado en Web",
            style: TextStyle(color: Colors.white),
          ),
        ),
        _closeButton(),
      ],
    );
  }

  Widget _closeButton() {
    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }
}
