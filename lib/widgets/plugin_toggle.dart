import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../models/plugin_state.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/haptics.dart';

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
    final l10n = AppLocalizations.of(context);
    final statusLabel = isRunning
        ? (l10n?.running ?? 'Running')
        : (l10n?.stopped ?? 'Stopped');
    final tap = (onToggle == null || isLoading)
        ? null
        : () {
            unawaited(AppHaptics.light(context.read<AppSettings>()));
            onToggle!(!isRunning);
          };
    return Semantics(
      // Merge the emoji icon, display name and running/stopped label into a
      // single screen-reader node so users hear "Adaptive Cruise Control,
      // running, toggle on" instead of each piece separately.
      container: true,
      label: '${plugin.displayName}, $statusLabel',
      toggled: isRunning,
      button: onToggle != null,
      child: Container(
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
                      color: isRunning
                          ? AppColors.orangeGlow
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ExcludeSemantics(
                      child: Center(
                        child: Text(plugin.iconEmoji,
                            style: const TextStyle(fontSize: 20)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plugin.displayName,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: isRunning
                                ? AppColors.success
                                : AppColors.textSecondary,
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
                    // The parent Semantics node already exposes the toggle
                    // state; hide the switch from a11y so screen readers
                    // don't announce "switch" a second time after the row
                    // label.
                    ExcludeSemantics(
                      child: Switch(
                        value: isRunning,
                        onChanged: onToggle == null
                            ? null
                            : (v) {
                                unawaited(AppHaptics.light(
                                    context.read<AppSettings>()));
                                onToggle!(v);
                              },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
