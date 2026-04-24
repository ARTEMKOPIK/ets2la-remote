/// Modal that renders the given [ConnectionProfile] as a QR so another
/// phone can scan it and import the same host/MAC in one step.
library;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../models/connection_profile.dart';
import '../services/profile_qr_codec.dart';
import '../theme/app_theme.dart';

Future<void> showProfileQrDialog(
  BuildContext context,
  ConnectionProfile profile,
) {
  final l10n = AppLocalizations.of(context);
  final payload = ProfileQrCodec.encode(profile);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        l10n?.shareProfile ?? 'Share profile',
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // White card around the code — scanners need strong contrast; a
          // dark-mode app that paints a QR on a dark surface reads badly
          // in practice.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 240,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Colors.black,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.name,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            profile.host,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            l10n?.ok ?? 'OK',
            style: const TextStyle(color: AppColors.orange),
          ),
        ),
      ],
    ),
  );
}
