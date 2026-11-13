import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../store/app_store.dart';
import '../theme/theme.dart';
import '../l10n/app_localizations.dart';
import 'parcel_detail_screen.dart';

class ScannerScreen extends StatefulWidget {
  final bool returnCodeOnly;

  const ScannerScreen({super.key, this.returnCodeOnly = false});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null && code.isNotEmpty) {
        _hasScanned = true;
        _processCode(code);
        break;
      }
    }
  }

  void _processCode(String code) {
    if (widget.returnCodeOnly) {
      Navigator.pop(context, code);
      return;
    }

    final store = context.read<AppStore>();
    final parcel = store.parcels.firstWhere(
      (p) => p.code.toLowerCase() == code.toLowerCase(),
      orElse: () => store.parcels.firstWhere(
        (p) => p.code.toLowerCase().contains(code.toLowerCase()),
        orElse: () => store.parcels.first,
      ),
    );

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(
        builder: (_) => ParcelDetailScreen(parcelId: parcel.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Glass overlay with scanning frame
          SafeArea(
            child: Column(
              children: [
                // Top control bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        icon: const Icon(
                          CupertinoIcons.back,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        icon: const Icon(
                          CupertinoIcons.bolt_fill,
                          color: Colors.white,
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                        ),
                        icon: const Icon(
                          CupertinoIcons.switch_camera_solid,
                          color: Colors.white,
                        ),
                        onPressed: () => _controller.switchCamera(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Center Reticle Card
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: RayoColors.primaryBlue, width: 3),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.tr('scan_hint'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),

                // Bottom Manual Entry Option
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    cornerRadius: 20,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualCodeController,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: context.tr('enter_code_manually'),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: RayoColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            final code = _manualCodeController.text.trim();
                            if (code.isNotEmpty) {
                              _processCode(code);
                            }
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
