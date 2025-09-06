import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/appwrite_service.dart';
import '../models/game_session.dart';
import 'phone_session_screen.dart';

class PhoneScanScreen extends StatefulWidget {
  const PhoneScanScreen({super.key});

  @override
  State<PhoneScanScreen> createState() => _PhoneScanScreenState();
}

class _PhoneScanScreenState extends State<PhoneScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AppwriteService _appwrite = AppwriteService();
  bool _handled = false;
  String? _error;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_handled) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final String? value = barcodes.first.rawValue;
    if (value == null || value.trim().isEmpty) return;
    setState(() => _handled = true);
    try {
      final GameSession? session = await _appwrite.getGameSession(value.trim());
      if (!mounted) return;
      if (session == null) {
        setState(() {
          _error = 'No game found for code';
          _handled = false;
        });
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PhoneSessionScreen(gameSession: session),
        ),
      );
    } catch (e) {
      setState(() {
        _error = 'Failed to load game';
        _handled = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Watch QR')),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleBarcode),
          if (_error != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _controller.toggleTorch();
        },
        child: const Icon(Icons.flash_on),
      ),
    );
  }
}
