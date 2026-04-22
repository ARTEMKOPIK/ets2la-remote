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

    final displayVer = updateInfo.displayVersion;
    final buildDate = updateInfo.buildDate;
    final notes = updateInfo.releaseNotes;
    final hasNotes = notes.isNotEmpty && notes != 'New update available';

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.system_update_rounded, color: AppColors.orange, size: 28),
          ),
          const SizedBox(height: 16),
          // Title
          Text(l10n?.updateAvailable ?? 'Update Available',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('v$displayVer',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.orange)),
          ),
          if (buildDate != null) ...[
            const SizedBox(height: 4),
            Text(buildDate,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 4),
          Text(updateInfo.formattedSize,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          // Release notes
          if (hasNotes) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n?.whatsNew ?? "What's new:",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 100),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: SingleChildScrollView(
                child: Text(notes,
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, height: 1.4)),
              ),
            ),
          ],
          // Download progress
          if (isDownloading) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${l10n?.downloading ?? 'Downloading'}… ${(progress * 100).toInt()}%',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.orange),
              ),
            ),
          ],
          // Downloaded success
          if (isDownloaded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successDim,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(l10n?.downloaded ?? 'Downloaded!',
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isDownloaded)
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: isDownloading ? null : () {
                    context.read<UpdateProvider>().downloadUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isDownloading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(l10n?.updateNow ?? 'Update Now',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            if (isDownloaded)
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    context.read<UpdateProvider>().installUpdate();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(l10n?.installUpdate ?? 'Install',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            if (!isMandatory && !isDownloading)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () {
                    context.read<UpdateProvider>().skipUpdate();
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n?.updateLater ?? 'Remind Me Later',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}