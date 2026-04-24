import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../models/connection_profile.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../services/lan_discovery_service.dart';
import '../services/port_probe_service.dart';
import '../services/vpn_detector.dart';
import '../services/wake_on_lan_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';
import '../widgets/ets2la_logo.dart';
import '../widgets/profile_qr_dialog.dart';
import 'connection_doctor_screen.dart';
import 'qr_scan_screen.dart';

/// Localized label for a [ConnectionStage]. Matches the short on-button
/// progress text to the user's current language so the flow feels native.
String _stageLabel(BuildContext context, ConnectionStage stage) {
  final l10n = AppLocalizations.of(context);
  switch (stage) {
    case ConnectionStage.pinging:
      return l10n?.stagePinging ?? 'Pinging…';
    case ConnectionStage.openingSocket:
      return l10n?.stageOpeningSocket ?? 'Opening socket…';
    case ConnectionStage.subscribing:
      return l10n?.stageSubscribing ?? 'Subscribing…';
    case ConnectionStage.idle:
      return l10n?.stageConnecting ?? 'Connecting…';
  }
}

/// Convert a [ConnectionErrorCode] name (or arbitrary message) into a
/// localized display string. Keeps provider decoupled from the widget tree.
String _localizedError(BuildContext context, String code) {
  final l10n = AppLocalizations.of(context);
  switch (code) {
    case 'unreachable':
      return l10n?.cannotReachServer ?? 'Cannot reach server';
    case 'failed':
      return l10n?.connectionFailed ?? 'Connection failed';
    case 'invalidHost':
      return l10n?.invalidHost ?? 'Enter a valid IP address or hostname';
  }
  return code;
}

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  final _ipFocus = FocusNode();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  bool _scanning = false;
  bool _scanFinished = false;
  List<DiscoveredHost> _discovered = const [];

  /// Per-host port-probe reports keyed by `host.address`. Populated by
  /// [_scanLan] right after mDNS discovery returns — probes run in
  /// parallel so the dots appear ~1 s after the tiles do.
  final Map<String, List<PortReport>> _probes = {};
  bool _vpnActive = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    // If there's no recent host to preselect, put focus on the IP field so
    // the user doesn't have to tap before typing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final conn = context.read<ConnectionProvider>();
      if (conn.recentHosts.isEmpty) {
        _ipFocus.requestFocus();
      }
    });

    // Check for active VPN interfaces; the warning banner only renders
    // when we actually see one, so users without a VPN don't get a
    // false-alarm in the connect flow.
    unawaited(_refreshVpnStatus());
  }

  Future<void> _refreshVpnStatus() async {
    final active = await VpnDetector.instance.isVpnActive();
    if (!mounted) return;
    if (active == _vpnActive) return;
    setState(() => _vpnActive = active);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _ipFocus.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  static final _ipRegex = RegExp(
    r'^((25[0-5]|2[0-4]\d|[01]?\d\d?)\.){3}(25[0-5]|2[0-4]\d|[01]?\d\d?)$',
  );
  // Hostname per RFC 1123 — letters, digits, hyphens, dots; must start/end
  // with alphanumeric per label. Accepts things like `mypc.local`,
  // `ets2la-desktop`, `host-01.lan`.
  static final _hostnameRegex = RegExp(
    r'^(?=.{1,253}$)([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$',
  );

  /// Accept literal IPv6 either bare (`::1`, `fe80::1`, `2001:db8::1`) or
  /// in bracketed form (`[2001:db8::1]`). The provider strips the brackets
  /// before use. We intentionally accept a permissive superset of RFC 3986
  /// here because the WebSocket / HTTP client will do the final validation
  /// — blocking a legitimate address via an overzealous regex would be
  /// worse UX than a single failed connect attempt.
  static final _ipv6Regex = RegExp(
    r'^\[?[0-9a-fA-F:]{2,}\]?$',
  );

  static bool _isValidHost(String host) =>
      _ipRegex.hasMatch(host) ||
      _hostnameRegex.hasMatch(host) ||
      _ipv6Regex.hasMatch(host);

  Future<void> _scanLan() async {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _scanFinished = false;
      _discovered = const [];
      _probes.clear();
    });
    try {
      final hosts = await LanDiscoveryService().scan();
      if (!mounted) return;
      setState(() => _discovered = hosts);
      // Fire off a parallel smart-scan (per-port health check) on every
      // discovered host and update the tiles as each one finishes. The
      // user sees the raw list immediately and the dots fill in
      // progressively — no need to block on the slow probes.
      final s = context.read<AppSettings>();
      final ports = <int>[s.portApi, s.portViz, s.portNav, s.portPages];
      for (final h in hosts) {
        unawaited(_probeHost(h, ports));
      }
    } finally {
      if (mounted) {
        setState(() {
          _scanning = false;
          _scanFinished = true;
        });
      }
    }
  }

  Future<void> _probeHost(DiscoveredHost host, List<int> ports) async {
    final reports =
        await PortProbeService.probeAllParallel(host.address, ports);
    if (!mounted) return;
    setState(() => _probes[host.address] = reports);
  }

  Future<void> _showProfileDialog(ConnectionProfile profile) async {
    final l10n = AppLocalizations.of(context);
    final nameCtrl = TextEditingController(text: profile.name);
    final hostCtrl = TextEditingController(text: profile.host);
    final macCtrl = TextEditingController(text: profile.mac ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          profile.name.isEmpty
              ? (l10n?.saveAsProfile ?? 'Save as profile')
              : (l10n?.edit ?? 'Edit'),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                autofocus: profile.name.isEmpty,
                decoration: InputDecoration(
                  labelText: l10n?.profileName ?? 'Name',
                  hintText: l10n?.profileHintHomePc ?? 'Home PC',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (l10n?.profileNameRequired ?? 'Enter a name')
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: hostCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.enterIp ?? 'Host',
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return l10n?.invalidHost ?? 'Invalid host';
                  if (!_isValidHost(s)) {
                    return l10n?.invalidHost ?? 'Invalid host';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: macCtrl,
                decoration: InputDecoration(
                  labelText: l10n?.macAddressOptional ?? 'MAC address (optional)',
                  hintText: 'AA:BB:CC:11:22:33',
                  helperText: l10n?.macAddressHelper ??
                      'Needed for Wake-on-LAN',
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return null;
                  if (!WakeOnLanService.isValidMac(s)) {
                    return l10n?.invalidMac ?? 'Invalid MAC address';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: Text(
              l10n?.save ?? 'Save',
              style: const TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );

    final newName = nameCtrl.text.trim();
    final newHost = hostCtrl.text.trim();
    final newMac = macCtrl.text.trim();
    nameCtrl.dispose();
    hostCtrl.dispose();
    macCtrl.dispose();

    if (saved == true && mounted) {
      await context.read<ConnectionProvider>().saveProfile(
            profile.copyWith(
              name: newName,
              host: newHost,
              mac: newMac.isEmpty ? null : newMac,
            ),
          );
    }
  }

  /// Explain why mDNS discovery may have failed. Shown after an empty
  /// LAN scan so the user has a concrete checklist instead of just
  /// "nothing was found".
  Future<void> _showMdnsHelpDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.help_outline_rounded,
                color: AppColors.orange, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.mdnsHelpTitle ?? 'ETS2LA not visible on the network',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            l10n?.mdnsHelpBody ??
                '• Make sure ETS2LA is running on your PC\n'
                    '• Both devices must be on the same Wi-Fi (not guest)\n'
                    '• Some routers block mDNS — enter the IP manually\n'
                    '• If you use a VPN, disconnect it first\n'
                    '• Windows Defender may block the port — see firewall command in Settings',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n?.ok ?? 'OK',
              style: const TextStyle(color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  /// Launch the QR scanner and, on success, save the scanned profile.
  /// We treat the scan as an "import" rather than a "connect now" — the
  /// user usually scans ahead of time to populate the list; a second tap
  /// then actually connects.
  Future<void> _scanQrProfile() async {
    final scanned = await Navigator.of(context).push<ConnectionProfile>(
      MaterialPageRoute(builder: (_) => const QrScanScreen()),
    );
    if (!mounted || scanned == null) return;
    final l10n = AppLocalizations.of(context);
    final conn = context.read<ConnectionProvider>();
    await conn.saveProfile(scanned);
    if (!mounted) return;
    AppToast.success(context, l10n?.profileImported ?? 'Profile imported');
    _ipController.text = scanned.host;
  }

  Future<void> _shareProfile(ConnectionProfile profile) async {
    await showProfileQrDialog(context, profile);
  }

  Future<void> _toggleFavourite(ConnectionProfile profile) async {
    await context.read<ConnectionProvider>().setFavouriteProfile(profile.id);
  }

  Future<void> _openConnectionDoctor() async {
    final host = _ipController.text.trim();
    final settings = context.read<AppSettings>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConnectionDoctorScreen(
          host: host.isEmpty ? null : host,
          portApi: settings.portApi,
          portViz: settings.portViz,
          portNav: settings.portNav,
          portPages: settings.portPages,
        ),
      ),
    );
  }

  Future<void> _wakeProfile(ConnectionProfile profile) async {
    final mac = profile.mac;
    final l10n = AppLocalizations.of(context);
    if (mac == null || mac.isEmpty) return;
    final ok = await WakeOnLanService.instance.wake(mac);
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            ok ? AppColors.toastSuccess : AppColors.toastError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
        content: Text(
          ok
              ? (l10n?.wolSent ?? 'Wake-on-LAN packet sent')
              : (l10n?.wolFailed ?? 'Failed to send Wake-on-LAN packet'),
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _connect() async {
    final host = _ipController.text.trim();
    if (host.isEmpty) return;
    if (!_isValidHost(host)) {
      final conn = context.read<ConnectionProvider>();
      conn.setError(ConnectionErrorCode.invalidHost.name);
      return;
    }

    final conn = context.read<ConnectionProvider>();
    final telem = context.read<TelemetryProvider>();
    final settings = context.read<AppSettings>();

    // Configure ports from settings before connecting
    conn.configurePorts(settings);

    final ok = await conn.connect(host);
    if (ok && mounted) {
      telem.init(conn.wsService, conn.navService, conn.apiService);
      telem.startPluginRefresh(conn.wsService, conn.navService, conn.apiService);
      // Suggest saving as a profile once we've confirmed the host actually
      // works. Only fires when the host isn't already saved as a profile,
      // so repeat-connects to known hosts don't pester the user.
      await _maybeSuggestSaveProfile(host);
      if (!mounted) return;
      // If we were pushed on top of Dashboard, just pop back
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  /// One-shot prompt: "You just connected to 192.168.1.5 — want to save it
  /// as a profile?". Intentionally lightweight (bottom-sheet with two
  /// options) so declining is one tap away.
  Future<void> _maybeSuggestSaveProfile(String host) async {
    if (!mounted) return;
    final conn = context.read<ConnectionProvider>();
    final already = conn.profiles.any((p) => p.host == host);
    if (already) return;
    final l10n = AppLocalizations.of(context);
    final save = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n?.saveAsProfileQuestion ??
                  'Save this connection as a profile?',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              host,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n?.cancel ?? 'Not now'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n?.save ?? 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (save == true && mounted) {
      await _showProfileDialog(ConnectionProfile(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: '',
        host: host,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      // Hide the AppBar on the initial launch (cold start) so the screen
      // reads as a welcome view, but expose it when pushed on top of the
      // Dashboard so the user can back out without a system gesture.
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: AppColors.textPrimary),
              title: Text(
                AppLocalizations.of(context)?.connect ?? 'Connect',
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600),
              ),
            )
          : null,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Ets2laLogo(size: 100),
                  const SizedBox(height: 48),

                  // Title
                  Text(
                    AppLocalizations.of(context)?.connectToServer ?? 'Connect to ETS2LA',
                    style: const TextStyle(fontFamily: 'Roboto', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.makeSureRunning ?? 'Enter the IP address of the PC running ETS2LA',
                    style: const TextStyle(fontFamily: 'Roboto', 
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // VPN Warning — only when a VPN-style interface is actually up.
                  if (_vpnActive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.vpn_key_rounded,
                              color: AppColors.orange, size: 16),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppLocalizations.of(context)?.vpnWarning ??
                                  'Warning: VPN may prevent connection',
                              style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: AppColors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 24),

                  // IP / hostname input
                  TextField(
                    controller: _ipController,
                    focusNode: _ipFocus,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.url,
                    inputFormatters: [
                      // Also allow `:`, `[`, `]` so users can type literal
                      // IPv6 addresses (e.g. `fe80::1`, `[2001:db8::1]`).
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9.:\-\[\]]')),
                      LengthLimitingTextInputFormatter(253),
                    ],
                    onChanged: (_) {
                      // Clear previous error as soon as user starts editing
                      context.read<ConnectionProvider>().clearError();
                    },
                    style: const TextStyle(fontFamily: 'Roboto',
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.hostnameOrIp ?? 'IP or hostname',
                      hintText: '192.168.1.100',
                      prefixIcon: const Icon(Icons.router_rounded,
                          color: AppColors.textSecondary),
                    ),
                    onSubmitted: (_) => _connect(),
                  ),
                  const SizedBox(height: 16),

                  // Error message
                  if (conn.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                      decoration: BoxDecoration(
                        color: AppColors.errorDim,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _localizedError(context, conn.errorMessage!),
                              style: const TextStyle(fontFamily: 'Roboto',
                                  fontSize: 13, color: AppColors.error),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.error),
                            tooltip: AppLocalizations.of(context)?.dismiss ?? 'Dismiss',
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                            onPressed: () => context.read<ConnectionProvider>().clearError(),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Connect button — while connecting, shows the current
                  // coarse-grained stage (Pinging / Opening socket /
                  // Subscribing) so the user has a clearer signal than a
                  // bare spinner when things take a few seconds.
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: conn.isConnecting ? null : _connect,
                      child: conn.isConnecting
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    _stageLabel(context, conn.stage),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              AppLocalizations.of(context)?.connect ?? 'Connect',
                              style: const TextStyle(fontFamily: 'Roboto', 
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Find on LAN
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _scanning ? null : _scanLan,
                      icon: _scanning
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.orange),
                            )
                          : const Icon(Icons.wifi_find_rounded,
                              color: AppColors.orange),
                      label: Text(
                        _scanning
                            ? (AppLocalizations.of(context)?.scanning ?? 'Scanning…')
                            : (AppLocalizations.of(context)?.findEts2la ?? 'Find ETS2LA on LAN'),
                        style: const TextStyle(fontFamily: 'Roboto', fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _scanQrProfile,
                          icon: const Icon(Icons.qr_code_scanner_rounded,
                              size: 18, color: AppColors.orange),
                          label: Text(
                            AppLocalizations.of(context)?.scanQr ?? 'Scan QR',
                            style: const TextStyle(
                                fontFamily: 'Roboto', fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openConnectionDoctor,
                          icon: const Icon(Icons.health_and_safety_rounded,
                              size: 18, color: AppColors.orange),
                          label: Text(
                            AppLocalizations.of(context)?.connectionDoctor ??
                                'Connection doctor',
                            style: const TextStyle(
                                fontFamily: 'Roboto', fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Empty-scan feedback
                  if (!_scanning && _scanFinished && _discovered.isEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  size: 16, color: AppColors.textMuted),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)
                                          ?.scanFinishedNoHosts ??
                                      "No ETS2LA found. Check it's running and on the same Wi-Fi.",
                                  style: const TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.help_outline_rounded,
                                  size: 16, color: AppColors.orange),
                              label: Text(
                                AppLocalizations.of(context)?.whyNotFound ??
                                    'Why not found?',
                                style: const TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: AppColors.orange),
                              ),
                              onPressed: () => _showMdnsHelpDialog(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Discovered hosts
                  if (_discovered.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)?.foundOnLan ?? 'Found on LAN',
                            style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: AppColors.textMuted),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._discovered.map((h) => _DiscoveredHostTile(
                          host: h,
                          reports: _probes[h.address],
                          onTap: () {
                            _ipController.text = h.address;
                            _connect();
                          },
                        )),
                  ],

                  const SizedBox(height: 24),

                  // Saved profiles
                  if (conn.profiles.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppLocalizations.of(context)?.profiles ?? 'Profiles',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...conn.profiles.map((profile) => _ProfileTile(
                          profile: profile,
                          onTap: () {
                            _ipController.text = profile.host;
                            _connect();
                          },
                          onEdit: () => _showProfileDialog(profile),
                          onRemove: () => context
                              .read<ConnectionProvider>()
                              .removeProfile(profile.id),
                          onWake: (profile.mac != null &&
                                  profile.mac!.isNotEmpty)
                              ? () => _wakeProfile(profile)
                              : null,
                          onShare: () => _shareProfile(profile),
                          onToggleFavourite: () => _toggleFavourite(profile),
                        )),
                  ],

                  // Recent hosts
                  if (conn.recentHosts.isNotEmpty) ...[
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(AppLocalizations.of(context)?.recent ?? 'Recent',
                              style: const TextStyle(fontFamily: 'Roboto', 
                                  fontSize: 12, color: AppColors.textMuted)),
                        ),
                        const Expanded(child: Divider(color: AppColors.surfaceBorder)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...conn.recentHosts.map((host) => _RecentHostTile(
                          host: host,
                          onTap: () {
                            _ipController.text = host;
                            _connect();
                          },
                          onRemove: () => context
                              .read<ConnectionProvider>()
                              .removeRecentHost(host),
                          onSaveAsProfile: () => _showProfileDialog(
                            ConnectionProfile(
                              id: DateTime.now().microsecondsSinceEpoch.toString(),
                              name: '',
                              host: host,
                            ),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveredHostTile extends StatelessWidget {
  final DiscoveredHost host;
  final VoidCallback onTap;

  /// Per-port reachability report from the smart-scan probe. `null`
  /// while the probe is in flight — we render a small pulsing indicator
  /// then; once populated we render one colored dot per port.
  final List<PortReport>? reports;

  const _DiscoveredHostTile({
    required this.host,
    required this.onTap,
    this.reports,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.orange.withOpacity(0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
            child: Row(
              children: [
                const Icon(Icons.wifi_tethering_rounded,
                    size: 18, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        host.instance.isEmpty ? host.address : host.instance,
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            color: AppColors.textPrimary),
                      ),
                      Row(
                        children: [
                          Text(
                            '${host.address}:${host.port}',
                            style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: AppColors.textMuted),
                          ),
                          const SizedBox(width: 8),
                          if (reports == null)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AppColors.textMuted,
                              ),
                            )
                          else
                            ...reports!.map(
                              (r) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: _PortDot(report: r),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortDot extends StatelessWidget {
  const _PortDot({required this.report});
  final PortReport report;

  @override
  Widget build(BuildContext context) {
    final ok = report.result == ProbeResult.reachable;
    return Tooltip(
      message: '${report.port} — '
          '${ok ? 'reachable' : 'blocked'}',
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: ok ? AppColors.success : AppColors.error,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RecentHostTile extends StatelessWidget {
  final String host;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onSaveAsProfile;

  const _RecentHostTile({
    required this.host,
    required this.onTap,
    required this.onRemove,
    required this.onSaveAsProfile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final removeLabel = l10n?.removeFromRecent ?? 'Remove';
    final saveLabel = l10n?.saveAsProfile ?? 'Save as profile';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(host,
                        style: const TextStyle(fontFamily: 'Roboto',
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined,
                      size: 18, color: AppColors.textSecondary),
                  tooltip: saveLabel,
                  onPressed: onSaveAsProfile,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                  tooltip: removeLabel,
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProfileMenuAction { share, edit, delete }

class _ProfileTile extends StatelessWidget {
  final ConnectionProfile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;
  final VoidCallback? onWake;
  final VoidCallback onShare;
  final VoidCallback onToggleFavourite;

  const _ProfileTile({
    required this.profile,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
    required this.onShare,
    required this.onToggleFavourite,
    this.onWake,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Condensed button row: wake (optional), favourite, overflow with
    // edit/share/delete. Keeps tap-targets large without an uncomfortably
    // wide row; Favourite is top-level because it's a per-profile state
    // the user often flips, while edit/share/delete are per-profile
    // actions that fit better under "…".
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: profile.favourite
              ? AppColors.orangeDim
              : AppColors.surfaceBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onEdit,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 4, 6),
            child: Row(
              children: [
                Icon(
                  profile.favourite
                      ? Icons.star_rounded
                      : Icons.bookmark_rounded,
                  size: 18,
                  color: AppColors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        profile.host,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onWake != null)
                  IconButton(
                    icon: const Icon(Icons.power_settings_new_rounded,
                        size: 18, color: AppColors.orange),
                    tooltip: l10n?.wakeHost ?? 'Wake host',
                    onPressed: onWake,
                    visualDensity: VisualDensity.compact,
                  ),
                IconButton(
                  icon: Icon(
                    profile.favourite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 20,
                    color: profile.favourite
                        ? AppColors.orange
                        : AppColors.textSecondary,
                  ),
                  tooltip: profile.favourite
                      ? (l10n?.unpinFavourite ?? 'Unpin')
                      : (l10n?.pinFavourite ?? 'Pin as default'),
                  onPressed: onToggleFavourite,
                  visualDensity: VisualDensity.compact,
                ),
                PopupMenuButton<_ProfileMenuAction>(
                  tooltip: '',
                  icon: const Icon(Icons.more_vert_rounded,
                      size: 20, color: AppColors.textSecondary),
                  onSelected: (action) {
                    switch (action) {
                      case _ProfileMenuAction.share:
                        onShare();
                        break;
                      case _ProfileMenuAction.edit:
                        onEdit();
                        break;
                      case _ProfileMenuAction.delete:
                        onRemove();
                        break;
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: _ProfileMenuAction.share,
                      child: Row(
                        children: [
                          const Icon(Icons.qr_code_rounded,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(l10n?.shareProfile ?? 'Share profile'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _ProfileMenuAction.edit,
                      child: Row(
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 18, color: AppColors.textSecondary),
                          const SizedBox(width: 10),
                          Text(l10n?.edit ?? 'Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _ProfileMenuAction.delete,
                      child: Row(
                        children: [
                          const Icon(Icons.delete_outline_rounded,
                              size: 18, color: AppColors.error),
                          const SizedBox(width: 10),
                          Text(
                            l10n?.deleteProfile ?? 'Delete profile',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
