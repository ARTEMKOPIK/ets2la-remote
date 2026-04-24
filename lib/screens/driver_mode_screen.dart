/// Landscape-oriented "driver mode" — a minimalist, high-contrast dash
/// intended for the phone sitting in a mount while the player drives.
///
/// Design intent:
///   * Huge speed readout (≥160 sp) so it's legible from arm's length.
///   * Autopilot / ACC status as big pills, not icons.
///   * Locks orientation to landscape and keeps the screen awake via
///     `wakelock_plus`.
///   * Single exit affordance (FAB) — we don't want the user to
///     accidentally navigate away while driving.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';

import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../theme/app_theme.dart';

class DriverModeScreen extends StatefulWidget {
  const DriverModeScreen({super.key});

  @override
  State<DriverModeScreen> createState() => _DriverModeScreenState();
}

class _DriverModeScreenState extends State<DriverModeScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    // Best-effort — wakelock_plus no-ops on unsupported platforms.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final telem = context.watch<TelemetryProvider>();
    final truck = telem.truckState;
    final autopilot = telem.autopilotStatus;
    final speed = truck.speedKmh.round();
    final limit = truck.speedLimitKmh.round();
    final overLimit = truck.isOverSpeedLimit;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Big speed — merged so TalkBack reads one sentence
                    // instead of "42" followed by "km/h" as two separate
                    // focus nodes. Include the over-limit state in the
                    // label so colour-blind users still get the warning
                    // (red-on-black carries no other affordance).
                    MergeSemantics(
                      child: Semantics(
                        label: overLimit
                            ? '$speed km/h, over the speed limit'
                            : '$speed km/h',
                        excludeSemantics: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$speed',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 180,
                                height: 0.9,
                                fontWeight: FontWeight.w800,
                                color: overLimit
                                    ? AppColors.error
                                    : AppColors.textPrimary,
                                letterSpacing: -4,
                              ),
                            ),
                            Text(
                              'km/h',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 22,
                                color: overLimit
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Status column
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _StatusPill(
                          label: l10n?.autopilot ?? 'Autopilot',
                          active: autopilot.steeringEnabled,
                        ),
                        const SizedBox(height: 12),
                        _StatusPill(
                          label: 'ACC',
                          active: autopilot.accEnabled,
                        ),
                        const SizedBox(height: 12),
                        if (limit > 0)
                          _LimitPill(
                            limit: limit,
                            overLimit: overLimit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Exit FAB — small, dim, top-left so it doesn't compete
            // with the speed readout for attention.
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppColors.textSecondary,
                  size: 28,
                ),
                tooltip: l10n?.exitDriverMode ?? 'Exit driver mode',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Connection status bottom-left.
            Positioned(
              bottom: 8,
              left: 16,
              child: Consumer<ConnectionProvider>(
                builder: (ctx, conn, _) => Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conn.isConnected
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      conn.isConnected
                          ? conn.currentHost
                          : (l10n?.notConnected ?? 'Not connected'),
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.active});
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, ${active ? 'on' : 'off'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.orangeDim : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? AppColors.orange : AppColors.surfaceBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: active ? AppColors.orange : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _LimitPill extends StatelessWidget {
  const _LimitPill({required this.limit, required this.overLimit});
  final int limit;
  final bool overLimit;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: overLimit
          ? 'Speed limit $limit, over the limit'
          : 'Speed limit $limit',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: overLimit ? AppColors.errorDim : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: overLimit ? AppColors.error : AppColors.surfaceBorder,
            width: 1.5,
          ),
        ),
        child: Text(
          'LIMIT $limit',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: overLimit ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
