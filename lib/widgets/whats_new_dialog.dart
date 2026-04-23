import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';

/// Shown once after a version upgrade so the user sees what changed.
/// [UpdateProvider.checkWhatsNew] prepares the payload; dismissing the
/// dialog clears it so the next launch is silent.
class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const WhatsNewDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upd = context.watch<UpdateProvider>();
    final notes = upd.whatsNewNotes;
    final version = upd.whatsNewVersion;
    if (notes == null) return const SizedBox.shrink();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.orangeGlow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.whatsNewTitle ?? "What's new",
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (version != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'v$version',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Text(
                notes,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<UpdateProvider>().dismissWhatsNew();
            Navigator.of(context).pop();
          },
          child: Text(
            l10n?.gotIt ?? 'Got it',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              color: AppColors.orange,
            ),
          ),
        ),
      ],
    );
  }
}
