import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../models/plugin_state.dart';
import '../theme/app_theme.dart';
import '../widgets/plugin_toggle.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Set<String> _loadingPlugins = {};

  Future<void> _togglePlugin(PluginInfo plugin, bool currentState) async {
    final api = context.read<ConnectionProvider>().apiService;
    setState(() => _loadingPlugins.add(plugin.id));

    try {
      // Use plugin.name (exact description.name from API) — works regardless of language
      if (currentState) {
        await api.disablePluginByName(plugin.name);
      } else {
        await api.enablePluginByName(plugin.name);
      }
    } finally {
      if (mounted) setState(() => _loadingPlugins.remove(plugin.id));
    }

    // Refresh plugin list
    final telem = context.read<TelemetryProvider>();
    final newList = await api.getPlugins();
    if (newList.isNotEmpty && mounted) {
      telem.updatePlugins(newList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telem = context.watch<TelemetryProvider>();
    final conn = context.watch<ConnectionProvider>();
    final plugins = telem.plugins;

    // Prioritized plugin order
    final priority = [
      'plugins.map',
      'plugins.adaptivecruisecontrol',
      'plugins.collisionavoidance',
      'plugins.ar',
      'plugins.hud',
      'plugins.tts',
      'plugins.visualizationsockets',
      'plugins.navigationsockets',
      'plugins.eventlistener',
      'plugins.discordrichpresence',
    ];

    final sorted = [...plugins]..sort((a, b) {
        final ai = priority.indexOf(a.id);
        final bi = priority.indexOf(b.id);
        if (ai == -1 && bi == -1) return a.name.compareTo(b.name);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.plugins ?? 'Plugins', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () async {
              final list = await conn.apiService.getPlugins();
              if (list.isNotEmpty && mounted) {
                telem.updatePlugins(list);
              }
            },
          ),
        ],
      ),
      body: plugins.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.extension_off_rounded,
                      color: AppColors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text(AppLocalizations.of(context)?.noPlugins ?? 'No plugins found',
                      style: GoogleFonts.inter(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.orangeGlow,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.orange.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Toggle plugins that are already loaded in ETS2LA',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.orange),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats row
                Row(
                  children: [
                    _StatChip(
                      label: 'Running',
                      count: sorted.where((p) => p.running).length,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Stopped',
                      count: sorted.where((p) => !p.running).length,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Plugin list
                ...sorted.map((plugin) => PluginToggle(
                      plugin: plugin,
                      isRunning: plugin.running,
                      isLoading: _loadingPlugins.contains(plugin.id),
                      onToggle: (val) => _togglePlugin(plugin, plugin.running),
                    )),
              ],
            ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
