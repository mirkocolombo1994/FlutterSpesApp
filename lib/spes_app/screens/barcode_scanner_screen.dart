import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/settings_provider.dart';

class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidRetailBarcode(String barcode) {
    if (!RegExp(r'^\d+$').hasMatch(barcode)) return false; // Solo numeri

    // Eccezione per i codici brevi "freschi" della nostra logica SpesApp (7 cifre, iniziano con 2)
    if (barcode.length == 7 && barcode.startsWith('2')) return true;

    // Lunghezza tipica EAN-8, UPC, EAN-13, ITF-14
    if (barcode.length < 8 || barcode.length > 14) return false;

    // Formula Modulo 10 (Checksum per EAN/UPC)
    // Partendo da destra a sinistra (escludendo l'ultima cifra che è il check digit),
    // si moltiplicano le posizioni per 3 o per 1 in modo alternato e si somma tutto.
    int sum = 0;
    int multiplier = 3;
    for (int i = barcode.length - 2; i >= 0; i--) {
      sum += int.parse(barcode[i]) * multiplier;
      multiplier = multiplier == 3 ? 1 : 3; // Alterna 3 e 1
    }

    int expectedCheckDigit = (10 - (sum % 10)) % 10;
    int actualCheckDigit = int.parse(barcode[barcode.length - 1]);

    return expectedCheckDigit == actualCheckDigit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scansiona Codice a Barre'),
      ),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final barcodeValue = barcodes.first.rawValue!;
            
            if (_isValidRetailBarcode(barcodeValue)) {
               _controller.stop();
               final settings = ref.read(settingsProvider);
               if (settings.playScanBeep) {
                 HapticFeedback.vibrate();
               }
               if(mounted) Navigator.pop(context, barcodeValue);
            }
          }
        },
      ),
    );
  }
}
