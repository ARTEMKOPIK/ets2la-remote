import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/truck_state.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import 'app_settings_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/ets2la_logo.dart';
import '../widgets/speed_gauge.dart';
import '../widgets/autopilot_card.dart';
import '../widgets/metric_card.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'connect_screen.dart';
import 'visualization_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final _pages = const [
    _DashboardTab(),
    MapScreen(),
    VisualizationScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final conn = context.watch<ConnectionProvider>();

    // Auto-disconnect redirect — only when fully disconnected and no active host
    if (!conn.isActiveOrConnecting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const ConnectScreen()),
          );
        }
      });
    }

    return Scaffold(
      // IndexedStack keeps all pages alive but wraps each in RepaintBoundary
      // so heavy screens (Unity, Map) don't trigger Flutter repaints
      body: IndexedStack(
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
        backgroundColor: success ? const Color(0xFF166534) : const Color(0xFF7F1D1D),
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
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    final ok = await conn.pagesService.toggleSteering();
    if (context.mounted) {
      if (!ok) {
        _showFirewallDialog(context);
      } else {
        _showToast(context, currentState ? (AppLocalizations.of(context)?.autopilotOff ?? 'Autopilot OFF') : (AppLocalizations.of(context)?.autopilotOn ?? 'Autopilot ON ✓'), success: true);
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
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }
    final ok = await conn.pagesService.toggleAcc();
    if (context.mounted) {
      if (!ok) {
        _showFirewallDialog(context);
      } else {
        _showToast(context, currentState ? (AppLocalizations.of(context)?.accOff ?? 'ACC OFF') : (AppLocalizations.of(context)?.accOn ?? 'ACC ON ✓'), success: true);
      }
    }
  }

  void _showFirewallDialog(BuildContext context) {
    const cmd = 'netsh advfirewall firewall add rule name="ETS2LA Pages" dir=in action=allow protocol=TCP localport=37523';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppColors.orange, size: 22),
            const SizedBox(width: 10),
            Text('One-time PC setup', style: TextStyle(fontFamily: 'Roboto', color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To control autopilot from your phone, open port 37523 on your PC (Windows Firewall). This is done once.',
              style: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Text('Run in PowerShell (Admin):', style: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 12)),
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
                style: GoogleFonts.robotoMono(color: AppColors.orange, fontSize: 11),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('OK', style: TextStyle(fontFamily: 'Roboto', color: AppColors.orange))),
        ],
      ),
    );
  }

  // ignore: unused_element
  Future<void> _togglePlugin(
      BuildContext context, String pluginId, bool currentState) async {
    final api = context.read<ConnectionProvider>().apiService;
    if (currentState) {
      await api.disablePluginById(pluginId);
    } else {
      await api.enablePluginById(pluginId);
    }
    await Future.delayed(const Duration(milliseconds: 500));
    final telem = context.read<TelemetryProvider>();
    final list = await api.getPlugins();
    if (list.isNotEmpty) telem.updatePlugins(list);
  }

  @override
  Widget build(BuildContext context) {
    final telem = context.watch<TelemetryProvider>();
    final conn = context.watch<ConnectionProvider>();
    final settings = context.watch<AppSettings>();
    final state = telem.truckState;
    final status = telem.autopilotStatus;

    return Scaffold(
      appBar: AppBar(
        title: const Ets2laLogoSmall(),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: conn.isConnected ? AppColors.success : AppColors.error,
                  boxShadow: [
                    BoxShadow(
                      color: (conn.isConnected ? AppColors.success : AppColors.error)
                          .withOpacity(0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppSettingsScreen()),
            ),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.power_settings_new_rounded),
            onPressed: () {
              context.read<TelemetryProvider>().reset();
              context.read<ConnectionProvider>().disconnect();
            },
            tooltip: 'Disconnect',
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                child: SpeedGauge(
                  speedKmh: state.speedKmh,
                  limitKmh: state.speedLimitKmh,
                  targetAccKmh: state.targetSpeedKmh,
                  size: MediaQuery.of(context).size.width * 0.82,
                  speedUnit: settings.speedUnitLabel,
                  maxSpeed: settings.gaugeMaxValue,
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
            'ACTIVE PLUGINS',
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
                  'GAME',
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
