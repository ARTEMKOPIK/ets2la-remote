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
import '../widgets/update_dialog.dart';
import 'app_settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/autopilot_card.dart';
import '../widgets/metric_card.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoConnect();
      _checkForUpdates();
    });
  }

  @override
  void dispose() {
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
    await upd.checkForUpdate();
    if (upd.hasUpdate && mounted) {
      UpdateDialog.show(context);
    }
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
            onTap: () => _showConnectionSheet(context),
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
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectScreen())); }, child: Text(conn.isConnected ? (l10n?.settings ?? 'Change') : (l10n?.connect ?? 'Connect')))),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  void _showToast(BuildContext context, String message, {bool success = true}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_outline_rounded,
              color: Colors.white, size: 18,
            ),
            const SizedBox(width: 10),
            Text(message,
                style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: success ? AppColors.toastSuccess : AppColors.toastError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleSteering(BuildContext context, bool currentState) async {
    final conn = context.read<ConnectionProvider>();
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
        _showFirewallDialog(context);
      } else {
        _showToast(context, currentState ? (AppLocalizations.of(context)?.autopilotOff ?? 'Autopilot OFF') : (AppLocalizations.of(context)?.autopilotOn ?? 'Autopilot ON'), success: true);
      }
    }
  }

  Future<void> _toggleAcc(BuildContext context, bool currentState) async {
    final conn = context.read<ConnectionProvider>();
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
        _showFirewallDialog(context);
      } else {
        _showToast(context, currentState ? (AppLocalizations.of(context)?.accOff ?? 'ACC OFF') : (AppLocalizations.of(context)?.accOn ?? 'ACC ON'), success: true);
      }
    }
  }

  void _showFirewallDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const cmd = 'netsh advfirewall firewall add rule name="ETS2LA Pages" dir=in action=allow protocol=TCP localport=37523';
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
              l10n?.firewallBody ?? 'To control autopilot from your phone, open port 37523 on your PC (Windows Firewall). This is done once.',
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
              await Clipboard.setData(const ClipboardData(text: cmd));
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
                    style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.orange),
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Autopilot main card
            AutopilotCard(
              steeringEnabled: status.steeringEnabled,
              accEnabled: status.accEnabled,
              onToggleSteering: () => _toggleSteering(context, status.steeringEnabled),
              onToggleAcc: () => _toggleAcc(context, status.accEnabled),
            ),
            const SizedBox(height: 16),

            // Speed gauge — isolated repaint
            Center(
              child: RepaintBoundary(
                child: Builder(
                  builder: (context) {
                    final mq = MediaQuery.of(context);
                    // Cap gauge by both width and height to avoid landscape overflow.
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
                    );
                  },
                ),
              ),
            ),

            // Turn indicators — only show when active
            if (state.isIndicatingLeft || state.isIndicatingRight) ...[  
              const SizedBox(height: 4),
              IndicatorWidget(
                leftActive: state.isIndicatingLeft,
                rightActive: state.isIndicatingRight,
              ),
            ],
            const SizedBox(height: 8),

            // Pedals — single combined card
            _PedalsCard(
              throttle: state.throttle,
              brake: state.brake,
              game: state.game,
            ),
            const SizedBox(height: 12),

            // Active plugins status
            if (settings.showActivePlugins)
              _StatusBar(status: status),
                  ],
                ),
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
            style: TextStyle(fontFamily: 'Roboto', 
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
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: 9, color: AppColors.textSecondary,
                    letterSpacing: 1.5, fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  game,
                  style: TextStyle(fontFamily: 'Roboto', 
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
              style: TextStyle(fontFamily: 'Roboto', 
                fontSize: 9, color: AppColors.textSecondary,
                letterSpacing: 1.5, fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: TextStyle(fontFamily: 'Roboto', 
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
    return IndexedStack(
      index: widget.index,
      children: List.generate(widget.children.length, (i) {
        if (!_activated[i]) return const SizedBox.shrink();
        return widget.children[i];
      }),
    );
  }
}

class _ConnectionChip extends StatelessWidget {
  final bool connected;
  final String host;
  final VoidCallback onTap;

  const _ConnectionChip({
    required this.connected,
    required this.host,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = connected
        ? (host.isNotEmpty ? host : (l10n?.connected ?? 'Connected'))
        : (l10n?.notConnected ?? 'Not connected');
    final color = connected ? AppColors.orange : AppColors.textMuted;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(connected ? Icons.wifi : Icons.wifi_off, color: color, size: 20),
              const SizedBox(width: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PluginChip extends StatelessWidget {
  final String name;
  final bool active;
  const _PluginChip({required this.name, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: TextStyle(fontFamily: 'Roboto', 
              fontSize: 11,
              color: active ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
