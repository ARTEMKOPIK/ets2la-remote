import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../models/plugin_state.dart';
import '../theme/app_theme.dart';

class PluginToggle extends StatelessWidget {
  final PluginInfo plugin;
  final bool isRunning;
  final bool isLoading;
  final ValueChanged<bool>? onToggle;

  const PluginToggle({
    super.key,
    required this.plugin,
    required this.isRunning,
    this.isLoading = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final tap = (onToggle == null || isLoading)
        ? null
        : () => onToggle!(!isRunning);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRunning
              ? AppColors.orange.withOpacity(0.25)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: tap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
          // Emoji icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRunning ? AppColors.orangeGlow : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(plugin.iconEmoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plugin.displayName,
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRunning 
                    ? (AppLocalizations.of(context)?.running ?? 'Running') 
                    : (AppLocalizations.of(context)?.stopped ?? 'Stopped'),
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: 12,
                    color: isRunning ? AppColors.success : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: isRunning,
              onChanged: onToggle,
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
