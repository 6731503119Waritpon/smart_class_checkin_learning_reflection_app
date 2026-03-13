import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final code = barcodes.first.rawValue!;
      
      // Validate: 10 digits and starts with 6 or 7 (e.g., 67xxxxxxxx, 70xxxxxxxx)
      final isValidStudentId = RegExp(r'^[67]\d{9}$').hasMatch(code);

      if (isValidStudentId) {
        setState(() => _scanned = true);
        Navigator.of(context).pop(code);
      } else {
        // Show error but don't close, let them scan again
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid QR: Expected a 10-digit Student ID, got: ${code.length > 15 ? "${code.substring(0, 15)}..." : code}'),
            backgroundColor: const Color(0xFFEF6B6B),
            duration: const Duration(seconds: 2),
          ),
        );
        // Add a small delay before allowing next scan to prevent spam
        setState(() => _scanned = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _scanned = false);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Dimmed overlay with cutout
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      color: Colors.red, // any opaque color works
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Border frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF8B7BF7).withValues(alpha: 0.7),
                  width: 2,
                ),
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C22).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Align QR code within the frame',
                  style: TextStyle(
                    color: Color(0xFFCCCCD0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
