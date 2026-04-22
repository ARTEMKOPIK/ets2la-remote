import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/update_provider.dart';
import '../theme/app_theme.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const UpdateDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upd = context.watch<UpdateProvider>();
    final updateInfo = upd.updateInfo;

    if (updateInfo == null) return const SizedBox.shrink();

    final isMandatory = updateInfo.isMandatory;
    final isDownloading = upd.state == UpdateState.downloading;
    final isDownloaded = upd.state == UpdateState.downloaded;
    final progress = upd.downloadProgress;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.system_update_alt, color: AppColors.orange, size: 28),
          const SizedBox(width: 8),
          Text(l10n?.updateAvailable ?? 'Update Available',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('v${updateInfo.version}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.orange)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n?.version ?? 'What\'s new:',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxHeight: 100),
            child: SingleChildScrollView(
              child: Text(updateInfo.releaseNotes,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
          ),
          if (isDownloading) ...[
            const SizedBox(height: 8),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${l10n?.updateNow ?? 'Downloading'}... ${(progress * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.textSecondary)),
                    Text(updateInfo.formattedSize,
                      style: const TextStyle(color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                ),
              ],
            ),
          ],
          if (isDownloaded) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.successDim,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n?.installUpdate ?? 'Downloaded!',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (!isMandatory && !isDownloading)
          TextButton(
            onPressed: () {
              context.read<UpdateProvider>().skipUpdate();
              Navigator.of(context).pop();
            },
            child: Text(l10n?.updateLater ?? 'Remind Me Later',
              style: const TextStyle(color: AppColors.textMuted)),
          ),
        if (!isDownloaded)
          ElevatedButton(
            onPressed: isDownloading ? null : () {
              context.read<UpdateProvider>().downloadUpdate();
            },
            child: isDownloading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary))
                : Text(l10n?.updateNow ?? 'Update Now'),
          ),
        if (isDownloaded)
          ElevatedButton(
            onPressed: () {
              context.read<UpdateProvider>().installUpdate();
              Navigator.of(context).pop();
            },
            child: Text(l10n?.installUpdate ?? 'Install'),
          ),
      ],
    );
  }
}