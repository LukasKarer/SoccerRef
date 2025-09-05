import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AMOLEDQrOverlay extends StatelessWidget {
  final String data;

  const AMOLEDQrOverlay({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: QrImageView(
            data: data,
            version: QrVersions.auto,
            size: MediaQuery.of(context).size.shortestSide * 0.6,
            backgroundColor: Colors.black,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ),
    );
  }
}
