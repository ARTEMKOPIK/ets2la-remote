import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/settings_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/update_provider.dart';
import '../widgets/update_dialog.dart';
import '../theme/app_theme.dart';
import 'dashboard_customize_screen.dart';
import 'trip_log_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  String _appVersion = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _appVersion = '${info.version}+${info.buildNumber}');
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final conn = context.watch<ConnectionProvider>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings',
            style: const TextStyle(
                fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── CONNECTION ─────────────────────────────────────────
          _SectionHeader(l10n?.connection ?? 'Connection'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.wifi_rounded,
              title: l10n?.autoConnectOnLaunch ?? 'Auto-connect on launch',
              subtitle: l10n?.reconnectToLastIp ??
                  'Reconnect to last IP automatically',
              value: s.autoConnect,
              onChanged: s.setAutoConnect,
            ),
            _Divider(),
            _SliderTile(
              icon: Icons.timer_rounded,
              title: l10n?.connectionTimeout ?? 'Connection timeout',
              subtitle: l10n?.secondsFormat(s.connectionTimeout) ??
                  '${s.connectionTimeout} seconds',
              value: s.connectionTimeout.toDouble(),
              min: 2,
              max: 15,
              divisions: 13,
              onChanged: (v) => s.setConnectionTimeout(v.round()),
            ),
          ]),

          _SectionHeader(l10n?.portsAdvanced ?? 'Ports (Advanced)'),
          _SettingsCard(children: [
            _PortTile(
                label: l10n?.portApiLabel ?? 'API (REST)',
                value: s.portApi,
                onChanged: s.setPortApi),
            _Divider(),
            _PortTile(
                label: l10n?.portVizLabel ?? 'Visualization (WS)',
                value: s.portViz,
                onChanged: s.setPortViz),
            _Divider(),
            _PortTile(
                label: l10n?.portNavLabel ?? 'Navigation (WS)',
                value: s.portNav,
                onChanged: s.setPortNav),
            _Divider(),
            _PortTile(
                label: l10n?.portPagesLabel ?? 'Pages (WS)',
                value: s.portPages,
                onChanged: s.setPortPages),
          ]),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4, right: 4),
            child: Text(
              l10n?.portsAdvancedHint ??
                  'Only change if ETS2LA uses non-default ports',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ),

          // ── APPEARANCE ─────────────────────────────────────────
          _SectionHeader(l10n?.appearance ?? 'Appearance'),
          _SettingsCard(children: [
            _SegmentTile(
              icon: Icons.speed_rounded,
              title: l10n?.speedUnits ?? 'Speed units',
              options: const ['km/h', 'mph'],
              selectedIndex: s.speedUnit.index,
              onChanged: (i) => s.setSpeedUnit(SpeedUnit.values[i]),
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.data_usage_rounded,
              title: l10n?.speedometerMax ?? 'Speedometer max',
              options: const ['160', '200', '250'],
              selectedIndex: s.gaugeMax.index,
              onChanged: (i) => s.setGaugeMax(GaugeMaxSpeed.values[i]),
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.extension_rounded,
              title: l10n?.showActivePlugins ?? 'Show Active Plugins',
              subtitle:
                  l10n?.pluginChipsOnDashboard ?? 'Plugin chips on Dashboard',
              value: s.showActivePlugins,
              onChanged: s.setShowActivePlugins,
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.language_rounded,
              title: l10n?.language ?? 'Language',
              options: [l10n?.languageSystem ?? 'System', 'English', 'Русский'],
              selectedIndex:
                  s.language == null ? 0 : (s.language == 'en' ? 1 : 2),
              onChanged: (i) =>
                  s.setLanguage(i == 0 ? null : (i == 1 ? 'en' : 'ru')),
            ),
            _Divider(),
            _AccentPickerTile(
              current: s.accentColor,
              onChanged: s.setAccentColor,
              label: l10n?.accentColorLabel ?? 'Accent color',
            ),
          ]),

          // ── ACCESSIBILITY ─────────────────────────────────────
          _SectionHeader(l10n?.accessibility ?? 'Accessibility'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.contrast_rounded,
              title: l10n?.highContrast ?? 'High contrast',
              subtitle: l10n?.highContrastHint ??
                  'Stronger borders for better visibility',
              value: s.highContrast,
              onChanged: s.setHighContrast,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.motion_photos_off_rounded,
              title: l10n?.reduceMotion ?? 'Reduce motion',
              subtitle:
                  l10n?.reduceMotionHint ?? 'Disable transitions and haptics',
              value: s.reduceMotion,
              onChanged: s.setReduceMotion,
            ),
          ]),

          // ── FEEDBACK ──────────────────────────────────────────
          _SectionHeader(l10n?.feedback ?? 'Feedback'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.vibration_rounded,
              title: l10n?.hapticEventsEnabled ?? 'Telemetry vibrations',
              subtitle: l10n?.hapticEventsHint ??
                  'Distinct patterns for autopilot / ACC / over-limit events',
              value: s.hapticEventsEnabled,
              onChanged: s.setHapticEventsEnabled,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.record_voice_over_rounded,
              title: l10n?.ttsEnabled ?? 'Voice cues',
              subtitle: l10n?.ttsEnabledHint ??
                  'Short spoken announcements on autopilot events',
              value: s.ttsEnabled,
              onChanged: s.setTtsEnabled,
            ),
          ]),

          // ── DRIVING ───────────────────────────────────────────
          _SectionHeader(l10n?.driverMode ?? 'Driver mode'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.screen_rotation_rounded,
              title: l10n?.driverModeAutoLandscape ?? 'Auto-enter on landscape',
              subtitle: l10n?.driverModeHint ??
                  'Big-text dashboard for the phone in a mount',
              value: s.driverModeAutoLandscape,
              onChanged: s.setDriverModeAutoLandscape,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.route_rounded,
              title: l10n?.tripLogEnabled ?? 'Record trip log',
              subtitle: l10n?.tripLogEnabledHint ??
                  'Save distance, duration, autopilot share per session',
              value: s.tripLogEnabled,
              onChanged: s.setTripLogEnabled,
            ),
            _Divider(),
            _NavTile(
              icon: Icons.history_rounded,
              title: l10n?.tripLog ?? 'Trip log',
              subtitle: l10n?.tripLogEnabledHint ??
                  'Past sessions and all-time totals',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TripLogScreen(),
                  ),
                );
              },
            ),
            _Divider(),
            _NavTile(
              icon: Icons.dashboard_customize_rounded,
              title: l10n?.customizeDashboard ?? 'Customize dashboard',
              subtitle: l10n?.customizeDashboardHint ??
                  'Pick and reorder the cards you want to see',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DashboardCustomizeScreen(),
                  ),
                );
              },
            ),
          ]),

          // ── MAP ────────────────────────────────────────────────
          _SectionHeader(l10n?.map ?? 'Map'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.my_location_rounded,
              title: l10n?.autoFollowTruck ?? 'Auto-follow truck',
              subtitle:
                  l10n?.keepTruckCentered ?? 'Keep truck centered by default',
              value: s.mapAutoFollow,
              onChanged: s.setMapAutoFollow,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.route_rounded,
              title: l10n?.showRoute ?? 'Show route',
              subtitle:
                  l10n?.displayNavRoute ?? 'Display navigation route on map',
              value: s.mapShowRoute,
              onChanged: s.setMapShowRoute,
            ),
            _Divider(),
            _SegmentTile(
              icon: Icons.layers_rounded,
              title: l10n?.mapStyle ?? 'Map style',
              options: [
                l10n?.mapStyleDark ?? 'Dark',
                l10n?.mapStyleLight ?? 'Light',
                l10n?.mapStyleSatellite ?? 'Satellite',
              ],
              selectedIndex: s.mapTileStyle.index,
              onChanged: (i) => s.setMapTileStyle(MapTileStyle.values[i]),
            ),
          ]),

          // ── 3D VIEW ────────────────────────────────────────────
          _SectionHeader(l10n?.view3d ?? '3D View'),
          _SettingsCard(children: [
            _SwitchTile(
              icon: Icons.dark_mode_rounded,
              title: l10n?.darkThemeByDefault ?? 'Dark theme by default',
              subtitle: l10n?.unityVizTheme ?? 'Unity visualization theme',
              value: s.vizDarkTheme,
              onChanged: s.setVizDarkTheme,
            ),
            _Divider(),
            _SwitchTile(
              icon: Icons.link_rounded,
              title: l10n?.autoConnectOnOpen ?? 'Auto-connect on open',
              subtitle: l10n?.connectWhenTabOpens ??
                  'Connect to ETS2LA when tab opens',
              value: s.vizAutoConnect,
              onChanged: s.setVizAutoConnect,
            ),
          ]),

          // ── ABOUT ──────────────────────────────────────────────
          _SectionHeader(l10n?.about ?? 'About'),
          _SettingsCard(children: [
            _InfoTile(
              icon: Icons.info_outline_rounded,
              title: AppLocalizations.of(context)?.version ?? 'Version',
              value: _appVersion,
            ),
            _Divider(),
            _InfoTile(
              icon: Icons.router_rounded,
              title:
                  AppLocalizations.of(context)?.connectedTo ?? 'Connected to',
              value: conn.currentHost.isNotEmpty ? conn.currentHost : '—',
            ),
            _Divider(),
            _TapTile(
              icon: Icons.code_rounded,
              title: l10n?.ets2laOnGithub ?? 'ETS2LA on GitHub',
              subtitle: 'github.com/ETS2LA',
              onTap: () => _launchUrl('https://github.com/ETS2LA'),
            ),
            _Divider(),
            _CheckUpdateTile(l10n: l10n),
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
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
          letterSpacing: 1.5,
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
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.orange),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

/// Row that navigates to another screen — no toggle, just a chevron.
/// Same visual footprint as [_SwitchTile] so sections of mixed tiles stay
/// aligned.
class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.orange),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
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
    required this.icon,
    required this.title,
    required this.options,
    required this.selectedIndex,
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
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.orange : Colors.transparent,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            selected ? Colors.white : AppColors.textSecondary,
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
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
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500))),
              Text(subtitle,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
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
class _PortTile extends StatefulWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _PortTile(
      {required this.label, required this.value, required this.onChanged});

  @override
  State<_PortTile> createState() => _PortTileState();
}

class _PortTileState extends State<_PortTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.settings_ethernet_rounded,
              size: 20, color: AppColors.orange),
          const SizedBox(width: 14),
          Expanded(
              child: Text(widget.label,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _editPort(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: const BoxConstraints(minHeight: 40, minWidth: 64),
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  '${widget.value}',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.orange,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editPort(BuildContext context) {
    final ctrl = TextEditingController(text: '${widget.value}');
    bool valid = true;
    // `showDialog` never completes before `dispose` is safe; tie the
    // controller lifetime to the dialog instead of leaking it on every edit.
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(widget.label,
              style: const TextStyle(
                  fontFamily: 'Roboto', color: AppColors.textPrimary)),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            autofocus: true,
            onChanged: (text) {
              final nextValid = _isPortTextValid(text);
              if (nextValid != valid) {
                setDialogState(() => valid = nextValid);
              }
            },
            onSubmitted: (_) => _submitPort(dialogContext, ctrl, () {
              setDialogState(() => valid = false);
            }),
            style: const TextStyle(
                fontFamily: 'Roboto',
                color: AppColors.textPrimary,
                fontSize: 18),
            decoration: InputDecoration(
              helperText: '1–65535',
              errorText: valid ? null : '1–65535',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel')),
            ElevatedButton(
              onPressed: () => _submitPort(dialogContext, ctrl, () {
                setDialogState(() => valid = false);
              }),
              child: Text(AppLocalizations.of(context)?.ok ?? 'Save'),
            ),
          ],
        ),
      ),
    ).whenComplete(ctrl.dispose);
  }

  bool _isPortTextValid(String text) {
    final v = int.tryParse(text);
    return v != null && v > 0 && v < 65536;
  }

  void _submitPort(
    BuildContext context,
    TextEditingController ctrl,
    VoidCallback onInvalid,
  ) {
    final v = int.tryParse(ctrl.text);
    if (v != null && v > 0 && v < 65536) {
      widget.onChanged(v);
      Navigator.pop(context);
    } else {
      onInvalid();
    }
  }
}

// ─── Info tile ────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile(
      {required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500))),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: AppColors.textSecondary)),
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

  const _TapTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.onTap});

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
                  Text(title,
                      style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ─── Check for update tile ────────────────────────────────────────────────────
class _CheckUpdateTile extends StatefulWidget {
  final AppLocalizations? l10n;
  const _CheckUpdateTile({required this.l10n});

  @override
  State<_CheckUpdateTile> createState() => _CheckUpdateTileState();
}

class _CheckUpdateTileState extends State<_CheckUpdateTile> {
  bool _checking = false;

  Future<void> _checkForUpdate() async {
    setState(() => _checking = true);
    final upd = context.read<UpdateProvider>();
    await upd.checkForUpdate(manual: true);
    if (!mounted) return;
    setState(() => _checking = false);

    if (upd.hasUpdate) {
      UpdateDialog.show(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(widget.l10n?.noUpdates ?? 'You\'re up to date',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: AppColors.toastSuccess,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _checking ? null : _checkForUpdate,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(Icons.system_update_rounded,
                size: 20,
                color: _checking ? AppColors.textMuted : AppColors.orange),
            const SizedBox(width: 14),
            Expanded(
              child: Text(widget.l10n?.checkForUpdates ?? 'Check for updates',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      color: _checking
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            if (_checking)
              const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.orange))
            else
              const Icon(Icons.refresh_rounded,
                  size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Compact 4-swatch accent-color picker. Doesn't try to be a full colour
/// wheel — the palette is fixed in [AccentColor] so users can't pick an
/// accent that clashes with the surface backgrounds.
class _AccentPickerTile extends StatelessWidget {
  final AccentColor current;
  final ValueChanged<AccentColor> onChanged;
  final String label;

  const _AccentPickerTile({
    required this.current,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.palette_rounded, size: 20, color: AppColors.orange),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: AccentColor.values.map((c) {
              final selected = c == current;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  selected: selected,
                  button: true,
                  label: c.name,
                  child: GestureDetector(
                    onTap: () => onChanged(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentFor(c),
                        border: Border.all(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.surfaceBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
