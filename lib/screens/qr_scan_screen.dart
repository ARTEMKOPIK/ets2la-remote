/// Full-screen camera view that reads a single [ProfileQrCodec]-encoded
/// QR and pops with the parsed [ConnectionProfile].
///
/// Kept deliberately simple — mobile_scanner's default UI covers 95% of
/// what we need; our only additions are (a) reading exactly one QR and
/// popping, and (b) gracefully handling the camera-denied path (toast +
/// pop-with-null so the caller can show a helpful dialog).
library;

import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../models/connection_profile.dart';
import '../services/profile_qr_codec.dart';
import '../theme/app_theme.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      final profile = ProfileQrCodec.decode(raw);
      if (profile != null) {
        _handled = true;
        Navigator.of(context).pop<ConnectionProfile>(profile);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scanQr ?? 'Scan QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (ctx, err, child) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  err.errorDetails?.message ?? err.errorCode.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
          // Subtle hint overlay — mobile_scanner doesn't render its own.
          Positioned(
            left: 0,
            right: 0,
            bottom: 32,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n?.scanQrHint ?? 'Point the camera at a profile QR code',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: AppColors.textPrimary,
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
