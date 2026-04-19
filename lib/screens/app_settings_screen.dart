import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/connection_provider.dart';
import '../theme/app_theme.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── CONNECTION ─────────────────────────────────────────
          _SectionHeader('Connection'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.wifi_rounded,
              title: 'Auto-connect on launch',
              subtitle: 'Reconnect to last IP automatically',
              value: s.autoConnect,
              onChanged: s.setAutoConnect,
            ),
            _Divider(),
            _SliderTile(
              icon: Icons.timer_rounded,
              title: 'Connection timeout',
              subtitle: '${s.connectionTimeout} seconds',
              value: s.connectionTimeout.toDouble(),
              min: 2, max: 15, divisions: 13,
              onChanged: (v) => s.setConnectionTimeout(v.round()),
            ),
          ]),

          _SectionHeader('Ports (Advanced)'),
          _SettingsCard(children: [
            _PortTile(label: 'API (REST)', value: s.portApi, onChanged: s.setPortApi),
            _Divider(),
            _PortTile(label: 'Visualization (WS)', value: s.portViz, onChanged: s.setPortViz),
            _Divider(),
            _PortTile(label: 'Navigation (WS)', value: s.portNav, onChanged: s.setPortNav),
            _Divider(),
            _PortTile(label: 'Pages (WS)', value: s.portPages, onChanged: s.setPortPages),
          ]),

          // ── APPEARANCE ─────────────────────────────────────────
          _SectionHeader('Appearance'),
          _SettingsCard(children: [
            _SegmentTile(
              icon: Icons.speed_rounded,
              title: 'Speed units',
              options: const ['km/h', 'mph'],
              selectedIndex: s.speedUnit.index,
              onChanged: (i) => s.setSpeedUnit(SpeedUnit.values[i]),
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.data_usage_rounded,
              title: 'Speedometer max',
              options: const ['160', '200', '250'],
              selectedIndex: s.gaugeMax.index,
              onChanged: (i) => s.setGaugeMax(GaugeMaxSpeed.values[i]),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.extension_rounded,
              title: 'Show Active Plugins',
              subtitle: 'Plugin chips on Dashboard',
              value: s.showActivePlugins,
              onChanged: s.setShowActivePlugins,
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.language_rounded,
              title: 'Language',
              options: const ['System', 'English', 'Русский'],
              selectedIndex: s.language == null ? 0 : (s.language == 'en' ? 1 : 2),
              onChanged: (i) => s.setLanguage(i == 0 ? null : (i == 1 ? 'en' : 'ru')),
            ),
            // DEBUG: show current locale
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Current: ${s.language ?? "system"}',
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ),
          ]),

          // ── MAP ────────────────────────────────────────────────
          _SectionHeader('Map'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.my_location_rounded,
              title: 'Auto-follow truck',
              subtitle: 'Keep truck centered by default',
              value: s.mapAutoFollow,
              onChanged: s.setMapAutoFollow,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.route_rounded,
              title: 'Show route',
              subtitle: 'Display navigation route on map',
              value: s.mapShowRoute,
              onChanged: s.setMapShowRoute,
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.layers_rounded,
              title: 'Map style',
              options: const ['Dark', 'Light', 'Satellite'],
              selectedIndex: s.mapTileStyle.index,
              onChanged: (i) => s.setMapTileStyle(MapTileStyle.values[i]),
            ),
          ]),

          // ── 3D VIEW ────────────────────────────────────────────
          _SectionHeader('3D View'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              title: 'Dark theme by default',
              subtitle: 'Unity visualization theme',
              value: s.vizDarkTheme,
              onChanged: s.setVizDarkTheme,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.link_rounded,
              title: 'Auto-connect on open',
              subtitle: 'Connect to ETS2LA when tab opens',
              value: s.vizAutoConnect,
              onChanged: s.setVizAutoConnect,
            ),
          ]),

          // ── ABOUT ──────────────────────────────────────────────
          _SectionHeader('About'),
          _SettingsCard(children: [
            _InfoTile(
              icon: Icons.info_outline_rounded,
              title: 'Version',
              value: '1.0.0',
            ),
            _Divider(),
            _InfoTile(
              icon: Icons.router_rounded,
              title: AppLocalizations.of(context)?.connectedTo ?? 'Connected to',
              value: conn.currentHost.isNotEmpty ? conn.currentHost : '—',
            ),
            _Divider(),
            _TapTile(
              icon: Icons.code_rounded,
              title: 'ETS2LA on GitHub',
              subtitle: 'github.com/ETS2LA',
              onTap: () {},
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: AppColors.textSecondary, letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ─── Card wrapper ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: AppColors.surfaceBorder, indent: 52);
}

// ─── Switch tile ──────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon, required this.title,
    this.subtitle, required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

// ─── Segment tile ─────────────────────────────────────────────────────────────
class _SegmentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentTile({
    required this.icon, required this.title,
    required this.options, required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: options.asMap().entries.map((e) {
                final selected = e.key == selectedIndex;
                return GestureDetector(
                  onTap: () => onChanged(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      e.value,
                      style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slider tile ──────────────────────────────────────────────────────────────
class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double value, min, max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon, required this.title, required this.subtitle,
    required this.value, required this.min, required this.max,
    required this.divisions, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.orange),
              const SizedBox(width: 14),
              Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
              Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.orange, fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: min, max: max, divisions: divisions,
            activeColor: AppColors.orange,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Port edit tile ───────────────────────────────────────────────────────────
class _PortTile extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _PortTile({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.settings_ethernet_rounded, size: 20, color: AppColors.orange),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () => _editPort(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                '$value',
                style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.orange, fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPort(BuildContext context) {
    final ctrl = TextEditingController(text: '$value');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(label, style: GoogleFonts.inter(color: AppColors.textPrimary)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0 && v < 65536) onChanged(v);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)?.ok ?? 'Save'),
          ),
        ],
      ),
    );
  }
}

// ─── Info tile ────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500))),
          Text(value, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─── Tap tile ─────────────────────────────────────────────────────────────────
class _TapTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _TapTile({required this.icon, required this.title, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
