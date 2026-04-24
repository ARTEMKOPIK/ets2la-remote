import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'connect_screen.dart';
import 'package:provider/provider.dart';
import '../models/truck_state.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/update_provider.dart';
import '../services/shortcut_service.dart';
import '../utils/haptics.dart';
import '../utils/toast.dart';
import '../widgets/update_dialog.dart';
import '../widgets/whats_new_dialog.dart';
import 'app_settings_screen.dart';
import 'onboarding_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/autopilot_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/telemetry_sparkline.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'visualization_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _updateChecked = false;
  StreamSubscription<int>? _shortcutSub;

  final _pages = const [
    _DashboardTab(),
    MapScreen(),
    VisualizationScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Launcher shortcuts either cold-start the app (getInitialTab) or poke
    // it while it's already running (tabRequests stream); handle both.
    ShortcutService.instance.getInitialTab().then((tab) {
      if (tab != null) _setTab(tab);
    });
    _shortcutSub = ShortcutService.instance.tabRequests.listen(_setTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowOnboarding();
      _tryAutoConnect();
      _checkForUpdates();
    });
  }

  /// Push the onboarding screen once per install. Runs post-frame so the
  /// app has already built its full widget tree (avoiding "pushed during
  /// build" asserts). No-op on subsequent launches.
  void _maybeShowOnboarding() {
    if (!mounted) return;
    final settings = context.read<AppSettings>();
    if (settings.hasSeenOnboarding) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  void _setTab(int tab) {
    if (!mounted) return;
    if (tab < 0 || tab >= _pages.length) return;
    setState(() => _currentIndex = tab);
  }

  @override
  void dispose() {
    _shortcutSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final telem = context.read<TelemetryProvider>();
    final conn = context.read<ConnectionProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        if (conn.isConnected) {
          telem.startPluginRefresh(conn.wsService, conn.navService, conn.apiService);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        telem.stopPluginRefresh();
        break;
    }
  }

  Future<void> _tryAutoConnect() async {
    final settings = context.read<AppSettings>();
    final conn = context.read<ConnectionProvider>();
    conn.configurePorts(settings);
    // Stale error from a previous session or a manual disconnect would
    // otherwise flash the red banner while we're happily reconnecting.
    conn.clearError();

    if (!settings.autoConnect) return;

    // Wait for recent hosts to load from disk before checking them —
    // otherwise we race against an empty list on cold start.
    await conn.ready;
    if (!mounted) return;

    final hosts = conn.recentHosts;
    if (hosts.isEmpty) return;

    final ok = await conn.connect(hosts.first);
    if (ok && mounted) {
      final telem = context.read<TelemetryProvider>();
      telem.init(conn.wsService, conn.navService, conn.apiService);
      telem.startPluginRefresh(conn.wsService, conn.navService, conn.apiService);
    }
  }

  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;
    final upd = context.read<UpdateProvider>();

    // Run the "What's new" probe in the background — it only fires after a
    // real version bump and doesn't need to block the update check.
    unawaited(_checkWhatsNew(upd));

    await upd.checkForUpdate();
    if (upd.hasUpdate && mounted) {
      UpdateDialog.show(context);
    }
  }

  Future<void> _checkWhatsNew(UpdateProvider upd) async {
    await upd.checkWhatsNew();
    if (!mounted || !upd.hasWhatsNew) return;
    WhatsNewDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context);
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ETS2LA'),
        actions: [
          _ConnectionChip(
            connected: conn.isConnected,
            host: conn.currentHost,
            pingMs: conn.lastPingMs,
            onTap: () => _showConnectionSheet(context),
            onLongPress: conn.isConnected
                ? () {
                  // Long-press provides the fastest path to disconnect
                  // without opening the connection sheet — particularly
                  // handy when the user is already one-handing the phone
                  // while driving. Vibration confirms the action.
                    AppHaptics.medium(
                      Provider.of<AppSettings>(context, listen: false),
                    );
                    conn.disconnect();
                  }
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 22),
            tooltip: l10n?.settings ?? 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
          ),
        ],
      ),
      // LazyIndexedStack keeps tabs alive after first visit
      // so heavy screens (Unity, Map) don't initialize on startup
      body: _LazyIndexedStack(
        index: _currentIndex,
        children: _pages
            .map((p) => RepaintBoundary(child: p))
            .toList(),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_rounded),
              label: l10n?.dashboard ?? 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_rounded),
              label: l10n?.map ?? 'Map',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.view_in_ar_rounded),
              label: l10n?.view3d ?? '3D View',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.tune_rounded),
              label: l10n?.plugins ?? 'Plugins',
            ),
          ],
        ),
      ),
    );
  }

  void _showConnectionSheet(BuildContext context) {
    final conn = context.read<ConnectionProvider>();
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n?.connect ?? 'Connection', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            Row(children: [
              Icon(conn.isConnected ? Icons.wifi : Icons.wifi_off, color: conn.isConnected ? AppColors.orange : AppColors.textMuted),
              const SizedBox(width: 8),
              Text(conn.isConnected ? (l10n?.connected ?? 'Connected') : (l10n?.disconnected ?? 'Disconnected'), style: TextStyle(color: conn.isConnected ? AppColors.orange : AppColors.textMuted)),
              if (conn.isConnected && conn.currentHost.isNotEmpty) ...[const SizedBox(width: 8), Text(conn.currentHost, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))],
            ]),
            const SizedBox(height: 20),
            Row(children: [
              if (conn.isConnected) Expanded(child: TextButton(onPressed: () { conn.disconnect(); Navigator.pop(ctx); }, child: Text(l10n?.disconnect ?? 'Disconnect'))),
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectScreen())); }, child: Text(conn.isConnected ? (l10n?.change ?? 'Change') : (l10n?.connect ?? 'Connect')))),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Is a plugin by its canonical id currently loaded-and-running on the
/// backend? Returns `true` when we just don't know (plugin list not yet
/// received) to avoid flashing a red "Plugin disabled" hint during the
/// first seconds after connect.
bool _pluginRunning(BuildContext context, String id) {
  final telem = context.watch<TelemetryProvider>();
  if (telem.plugins.isEmpty) return true;
  for (final p in telem.plugins) {
    if (p.id == id) return p.running;
  }
  return false;
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  Future<void> _toggleSteering(BuildContext context, bool currentState) async {
    final conn = context.read<ConnectionProvider>();
    final settings = context.read<AppSettings>();
    // Medium-impact haptic fires on intent, not on result, so the user gets
    // immediate feedback even while the plugin-enable round-trip runs.
    unawaited(AppHaptics.medium(settings));
    if (!currentState) {
      final telem = context.read<TelemetryProvider>();
      final mapPlugin = telem.plugins.where((p) => p.id == 'plugins.map').firstOrNull;
      if (mapPlugin != null && !mapPlugin.running) {
        await conn.apiService.enablePluginByName(mapPlugin.name);
        if (!context.mounted) return;
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    if (!context.mounted) return;
    final ok = await conn.pagesService.toggleSteering();
    if (context.mounted) {
      if (!ok) {
        // Debounce the firewall dialog — one random glitch shouldn't
        // throw a "fix your firewall" wall of text at the user.
        if (conn.registerPagesFailureShouldShowDialog()) {
          _showFirewallDialog(context);
        } else {
          context.showErrorToast(
              AppLocalizations.of(context)?.connectionFailed ??
                  'Connection failed');
        }
      } else {
        conn.resetFirewallFailStreak();
        context.showSuccessToast(currentState
            ? (AppLocalizations.of(context)?.autopilotOff ?? 'Autopilot OFF')
            : (AppLocalizations.of(context)?.autopilotOn ?? 'Autopilot ON'));
      }
    }
  }

  Future<void> _toggleAcc(BuildContext context, bool currentState) async {
    final conn = context.read<ConnectionProvider>();
    final settings = context.read<AppSettings>();
    unawaited(AppHaptics.medium(settings));
    if (!currentState) {
      final telem = context.read<TelemetryProvider>();
      final accPlugin = telem.plugins
          .where((p) => p.id == 'plugins.adaptivecruisecontrol')
          .firstOrNull;
      if (accPlugin != null && !accPlugin.running) {
        await conn.apiService.enablePluginByName(accPlugin.name);
        if (!context.mounted) return;
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    if (!context.mounted) return;
    final ok = await conn.pagesService.toggleAcc();
    if (context.mounted) {
      if (!ok) {
        if (conn.registerPagesFailureShouldShowDialog()) {
          _showFirewallDialog(context);
        } else {
          context.showErrorToast(
              AppLocalizations.of(context)?.connectionFailed ??
                  'Connection failed');
        }
      } else {
        conn.resetFirewallFailStreak();
        context.showSuccessToast(currentState
            ? (AppLocalizations.of(context)?.accOff ?? 'ACC OFF')
            : (AppLocalizations.of(context)?.accOn ?? 'ACC ON'));
      }
    }
  }

  Widget _buildNarrowLayout(
    BuildContext context,
    TruckState state,
    AutopilotStatus status,
    AppSettings settings,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AutopilotCard(
            steeringEnabled: status.steeringEnabled,
            accEnabled: status.accEnabled,
            steeringPluginRunning: _pluginRunning(context, 'plugins.map'),
            accPluginRunning:
                _pluginRunning(context, 'plugins.adaptivecruisecontrol'),
            onToggleSteering: () => _toggleSteering(context, status.steeringEnabled),
            onToggleAcc: () => _toggleAcc(context, status.accEnabled),
          ),
          const SizedBox(height: 16),
          Center(
            child: RepaintBoundary(
              child: Builder(
                builder: (context) {
                  final mq = MediaQuery.of(context);
                  final gaugeSize = [
                    mq.size.width * 0.82,
                    mq.size.height * 0.45,
                    420.0,
                  ].reduce((a, b) => a < b ? a : b);
                  return SpeedGauge(
                    speedKmh: state.speedKmh,
                    limitKmh: state.speedLimitKmh,
                    targetAccKmh: state.targetSpeedKmh,
                    size: gaugeSize,
                    speedUnit: settings.speedUnitLabel,
                    maxSpeed: settings.gaugeMaxValue,
                    convertFromKmh: settings.speedFromKmh,
                  );
                },
              ),
            ),
          ),
          if (state.isIndicatingLeft || state.isIndicatingRight) ...[
            const SizedBox(height: 4),
            IndicatorWidget(
              leftActive: state.isIndicatingLeft,
              rightActive: state.isIndicatingRight,
            ),
          ],
          const SizedBox(height: 12),
          _SpeedSparklineCard(
            maxSpeed: settings.gaugeMaxValue,
            speedUnitLabel: settings.speedUnitLabel,
          ),
          const SizedBox(height: 12),
          _PedalsCard(
            throttle: state.throttle,
            brake: state.brake,
            game: state.game,
          ),
          const SizedBox(height: 12),
          if (settings.showActivePlugins) _StatusBar(status: status),
        ],
      ),
    );
  }

  Widget _buildWideLayout(
    BuildContext context,
    BoxConstraints constraints,
    TruckState state,
    AutopilotStatus status,
    AppSettings settings,
  ) {
    // Gauge fills the left column; cap both by width and by available height
    // so it never pushes the pedals card off-screen.
    final leftWidth = constraints.maxWidth * 0.48;
    final gaugeSize = [
      leftWidth * 0.9,
      constraints.maxHeight - 32,
      480.0,
    ].reduce((a, b) => a < b ? a : b);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: gauge + indicators
          SizedBox(
            width: leftWidth,
            child: Column(
              children: [
                Center(
                  child: RepaintBoundary(
                    child: SpeedGauge(
                      speedKmh: state.speedKmh,
                      limitKmh: state.speedLimitKmh,
                      targetAccKmh: state.targetSpeedKmh,
                      size: gaugeSize,
                      speedUnit: settings.speedUnitLabel,
                      maxSpeed: settings.gaugeMaxValue,
                      convertFromKmh: settings.speedFromKmh,
                    ),
                  ),
                ),
                if (state.isIndicatingLeft || state.isIndicatingRight) ...[
                  const SizedBox(height: 8),
                  IndicatorWidget(
                    leftActive: state.isIndicatingLeft,
                    rightActive: state.isIndicatingRight,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Right: autopilot + pedals + plugins
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AutopilotCard(
                  steeringEnabled: status.steeringEnabled,
                  accEnabled: status.accEnabled,
                  steeringPluginRunning:
                      _pluginRunning(context, 'plugins.map'),
                  accPluginRunning: _pluginRunning(
                      context, 'plugins.adaptivecruisecontrol'),
                  onToggleSteering: () => _toggleSteering(context, status.steeringEnabled),
                  onToggleAcc: () => _toggleAcc(context, status.accEnabled),
                ),
                const SizedBox(height: 12),
                _SpeedSparklineCard(
                  maxSpeed: settings.gaugeMaxValue,
                  speedUnitLabel: settings.speedUnitLabel,
                ),
                const SizedBox(height: 12),
                _PedalsCard(
                  throttle: state.throttle,
                  brake: state.brake,
                  game: state.game,
                ),
                if (settings.showActivePlugins) ...[
                  const SizedBox(height: 12),
                  _StatusBar(status: status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFirewallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Use the port the user actually runs the Pages server on; falling
    // back to the default only if AppSettings hasn't initialised yet.
    final pagesPort = context.read<AppSettings>().portPages;
    final cmd =
        'netsh advfirewall firewall add rule name="ETS2LA Pages" dir=in action=allow protocol=TCP localport=$pagesPort';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.orange, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(l10n?.firewallTitle ?? 'One-time PC setup',
                  style: const TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.firewallBody(pagesPort) ??
                  'To control autopilot from your phone, open port $pagesPort on your PC (Windows Firewall). This is done once.',
              style: const TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text(l10n?.runInPowerShell ?? 'Run in PowerShell (Admin):',
                style: const TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: SelectableText(
                cmd,
                style: const TextStyle(fontFamily: 'RobotoMono', color: AppColors.orange, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textSecondary),
            label: Text(l10n?.copy ?? 'Copy',
                style: const TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary)),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: cmd));
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(ctx)?.copied ?? 'Copied'),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n?.ok ?? 'OK',
                style: const TextStyle(fontFamily: 'Roboto', color: AppColors.orange)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telem = context.watch<TelemetryProvider>();
    final conn = context.watch<ConnectionProvider>();
    final settings = context.watch<AppSettings>();
    final state = telem.truckState;
    final status = telem.autopilotStatus;

    return Scaffold(
      body: Column(
        children: [
          // Reconnect banner
          if (!conn.isConnected && conn.currentHost.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              color: AppColors.orangeDim,
              child: Row(
                children: [
                  const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
                  const SizedBox(width: 10),
                  Text(
                    AppLocalizations.of(context)?.reconnecting ?? 'Reconnecting...',
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.orange),
                  ),
                ],
              ),
            ),
          // "Waiting for telemetry" banner — shown once we're connected but
          // the game isn't yet streaming data. TruckState.time stays 0 until
          // the first real telemetry payload arrives, so it's a reliable
          // "is the simulator actually sending data" signal without having
          // to plumb a separate flag through.
          if (conn.isConnected && state.time == 0)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(color: AppColors.surfaceBorder),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.waitingForGameTitle ??
                              'Waiting for telemetry',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)?.waitingForGameBody ??
                              'Launch ETS2 or ATS and enable the Map plugin in ETS2LA.',
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                final api = context.read<ConnectionProvider>().apiService;
                final telem = context.read<TelemetryProvider>();
                final list = await api.getPlugins();
                if (list.isNotEmpty) telem.updatePlugins(list);
              },
              color: AppColors.orange,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Wide = landscape phone / tablet. Threshold picked so that
                  // a Pixel 7 in landscape (~850dp) gets the side-by-side
                  // layout but a compact phone in portrait (~412dp) does not.
                  final wide = constraints.maxWidth >= 720;
                  return wide
                      ? _buildWideLayout(context, constraints, state, status, settings)
                      : _buildNarrowLayout(context, state, status, settings);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final AutopilotStatus status;
  const _StatusBar({required this.status});

  @override
  Widget build(BuildContext context) {
    final all = [...status.enabled, ...status.disabled];
    if (all.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.plugins ?? 'ACTIVE PLUGINS',
            style: const TextStyle(fontFamily: 'Roboto', 
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              ...status.enabled.map((name) => _PluginChip(name: name, active: true)),
              ...status.disabled.map((name) => _PluginChip(name: name, active: false)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Speed Sparkline Card ───────────────────────────────────────
class _SpeedSparklineCard extends StatelessWidget {
  final double maxSpeed;
  final String speedUnitLabel;

  const _SpeedSparklineCard({
    required this.maxSpeed,
    required this.speedUnitLabel,
  });

  void _showStats(BuildContext context, List<double> historyKmh) {
    if (historyKmh.isEmpty) return;
    final settings = context.read<AppSettings>();
    // Last-60s stats. speedHistory is sampled at ~1Hz and capped at 60
    // samples by TelemetryProvider, so the full buffer is already the
    // "last 60 seconds" window.
    double sum = 0, max = historyKmh.first, min = historyKmh.first;
    for (final v in historyKmh) {
      sum += v;
      if (v > max) max = v;
      if (v < min) min = v;
    }
    final avg = sum / historyKmh.length;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.sparklineStatsTitle ?? 'Last 60 seconds',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            _StatRow(
              label: l10n?.sparklineAvg ?? 'Avg',
              value: '${settings.speedDisplay(avg)} $speedUnitLabel',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: l10n?.sparklineMax ?? 'Max',
              value: '${settings.speedDisplay(max)} $speedUnitLabel',
            ),
            const SizedBox(height: 8),
            _StatRow(
              label: l10n?.sparklineMin ?? 'Min',
              value: '${settings.speedDisplay(min)} $speedUnitLabel',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final telem = context.watch<TelemetryProvider>();
    final history = telem.speedHistory;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                (AppLocalizations.of(context)?.speed ?? 'SPEED').toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                '${context.read<AppSettings>().speedDisplay(telem.truckState.speedKmh)} $speedUnitLabel',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          history.length < 2
              ? SizedBox(
                  height: 56,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)?.collectingData ??
                          'Collecting data…',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                )
              : Semantics(
                  button: true,
                  label: AppLocalizations.of(context)?.sparklineStatsTitle ??
                      'Last 60 seconds',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showStats(context, history),
                    child: RepaintBoundary(
                      child: TelemetrySparkline(
                        values: history,
                        color: AppColors.orange,
                        maxY: maxSpeed,
                        height: 56,
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Pedals Card ────────────────────────────────────────────────
class _PedalsCard extends StatelessWidget {
  final double throttle;
  final double brake;
  final String game;

  const _PedalsCard({
    required this.throttle,
    required this.brake,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          // Throttle
          Expanded(
            child: _PedalItem(
              label: AppLocalizations.of(context)?.gas ?? 'GAS',
              value: throttle,
              color: AppColors.success,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
          const SizedBox(width: 12),
          // Brake
          Expanded(
            child: _PedalItem(
              label: AppLocalizations.of(context)?.brake ?? 'BRAKE',
              value: brake,
              color: AppColors.error,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          const SizedBox(width: 12),
          // Game badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)?.game ?? 'GAME',
                  style: const TextStyle(fontFamily: 'Roboto', 
                    fontSize: 9, color: AppColors.textSecondary,
                    letterSpacing: 1.5, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  game,
                  style: const TextStyle(fontFamily: 'Roboto', 
                    fontSize: 14, color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PedalItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _PedalItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 11, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontFamily: 'Roboto', 
                fontSize: 9, color: AppColors.textSecondary,
                letterSpacing: 1.5, fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: const TextStyle(fontFamily: 'Roboto', 
                fontSize: 11, color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.surfaceElevated,
            valueColor: AlwaysStoppedAnimation<Color>(
              value > 0.01 ? color : AppColors.textMuted,
            ),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ─── Lazy Indexed Stack ───────────────────────────────────────────────────────
class _LazyIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;

  const _LazyIndexedStack({
    required this.index,
    required this.children,
  });

  @override
  State<_LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<_LazyIndexedStack> {
  late List<bool> _activated;

  @override
  void initState() {
    super.initState();
    _activated = List.generate(widget.children.length, (i) => i == widget.index);
  }

  @override
  void didUpdateWidget(_LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _activated[widget.index] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Respect reduce-motion: when enabled, skip the 150ms fade entirely and
    // snap between tabs. Avoids vestibular discomfort for users who opt in.
    final reduceMotion =
        context.select<AppSettings, bool>((s) => s.reduceMotion);
    return Stack(
      children: List.generate(widget.children.length, (i) {
        if (!_activated[i]) return const SizedBox.shrink();
        final active = i == widget.index;
        return IgnorePointer(
          ignoring: !active,
          child: AnimatedOpacity(
            opacity: active ? 1.0 : 0.0,
            // Short cross-fade makes tab switches feel less abrupt without
            // being noticeably slow. 150ms is Material's "short2" duration.
            duration:
                Duration(milliseconds: reduceMotion ? 0 : 150),
            curve: Curves.easeInOut,
            child: Offstage(offstage: !active, child: widget.children[i]),
          ),
        );
      }),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final bool connected;
  final String host;
  final int? pingMs;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ConnectionChip({
    required this.connected,
    required this.host,
    required this.onTap,
    this.pingMs,
    this.onLongPress,
  });

  /// Bucketed colour for a measured latency — green under 60ms feels
  /// LAN-fast, amber up to 200ms is "fine", red above is visibly laggy.
  Color _pingColor(int ms) {
    if (ms <= 60) return AppColors.success;
    if (ms <= 200) return AppColors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = connected
        ? (host.isNotEmpty ? host : (l10n?.connected ?? 'Connected'))
        : (l10n?.notConnected ?? 'Not connected');
    final color = connected ? AppColors.orange : AppColors.textMuted;
    final showPing = connected && pingMs != null;
    return Semantics(
      button: true,
      label: showPing
          ? '$label, ${l10n?.pingLabel ?? "Ping"} ${pingMs}ms'
          : label,
      child: Tooltip(
        message:
            connected ? (l10n?.disconnectHint ?? 'Hold to disconnect') : label,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(connected ? Icons.wifi : Icons.wifi_off,
                    color: color, size: 20),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showPing) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: _pingColor(pingMs!).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pingMs}ms',
                      style: TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _pingColor(pingMs!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 14,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PluginChip extends StatelessWidget {
  final String name;
  final bool active;
  const _PluginChip({required this.name, required this.active});

  @override
  Widget build(BuildContext context) {
    // Plugin chips are read-only status indicators — wrapping them in a
    // Semantics node (with `button: false`) prevents TalkBack announcing
    // them as tappable. Visually they carry their own colour, so we also
    // bake the active/inactive state into the label for screen readers.
    return Semantics(
      button: false,
      label: '$name, ${active ? "active" : "inactive"}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.successDim : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.success.withOpacity(0.3)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active ? AppColors.success : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: active ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
