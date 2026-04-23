import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ets2la_logo.dart';

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

  Future<void> _connect() async {
    final host = _ipController.text.trim();
    if (host.isEmpty) return;
    if (!_ipRegex.hasMatch(host)) {
      final conn = context.read<ConnectionProvider>();
      conn.setError(AppLocalizations.of(context)?.invalidIp ?? 'Enter a valid IPv4 address');
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
      // If we were pushed on top of Dashboard, just pop back
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Scaffold(
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
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.makeSureRunning ?? 'Enter the IP address of the PC running ETS2LA',
                    style: TextStyle(fontFamily: 'Roboto', 
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // VPN Warning
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.vpn_key_rounded, color: AppColors.orange, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)?.vpnWarning ?? 'Warning: VPN may prevent connection',
                            style: TextStyle(fontFamily: 'Roboto', fontSize: 12, color: AppColors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // IP Input
                  TextField(
                    controller: _ipController,
                    focusNode: _ipFocus,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    onChanged: (_) {
                      // Clear previous error as soon as user starts editing
                      context.read<ConnectionProvider>().clearError();
                    },
                    style: TextStyle(fontFamily: 'Roboto',
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.enterIp ?? 'IP Address',
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
                              conn.errorMessage!,
                              style: TextStyle(fontFamily: 'Roboto',
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

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: conn.isConnecting ? null : _connect,
                      child: conn.isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)?.connect ?? 'Connect',
                              style: TextStyle(fontFamily: 'Roboto', 
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent hosts
                  if (conn.recentHosts.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.surfaceBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(AppLocalizations.of(context)?.recent ?? 'Recent',
                              style: TextStyle(fontFamily: 'Roboto', 
                                  fontSize: 12, color: AppColors.textMuted)),
                        ),
                        Expanded(child: Divider(color: AppColors.surfaceBorder)),
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

class _RecentHostTile extends StatelessWidget {
  final String host;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentHostTile({
    required this.host,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final removeLabel = AppLocalizations.of(context)?.removeFromRecent ?? 'Remove';
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
                        style: TextStyle(fontFamily: 'Roboto',
                            fontSize: 14, color: AppColors.textPrimary)),
                  ),
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
