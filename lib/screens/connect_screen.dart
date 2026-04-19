import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/ets2la_logo.dart';
import 'dashboard_screen.dart';

class ConnectScreen extends StatefulWidget {
  const ConnectScreen({super.key});

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen>
    with SingleTickerProviderStateMixin {
  final _ipController = TextEditingController();
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    // Auto-connect if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoConnect());
  }

  Future<void> _checkAutoConnect() async {
    final settings = context.read<AppSettings>();
    final conn = context.read<ConnectionProvider>();
    // Wait a bit for SharedPreferences to load recentHosts asynchronously
    if (settings.autoConnect) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final hosts = context.read<ConnectionProvider>().recentHosts;
      if (hosts.isNotEmpty) {
        _ipController.text = hosts.first;
        await _connect();
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final host = _ipController.text.trim();
    if (host.isEmpty) return;

    final conn = context.read<ConnectionProvider>();
    final telem = context.read<TelemetryProvider>();

    final ok = await conn.connect(host);
    if (ok && mounted) {
      telem.init(conn.wsService, conn.navService, conn.apiService);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
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
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.makeSureRunning ?? 'Enter the IP address of the PC running ETS2LA',
                    style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.orange),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // IP Input
                  TextField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: AppColors.textPrimary,
                      letterSpacing: 1,
                    ),
                    decoration: InputDecoration(
                      labelText: 'IP Address',
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
                      padding: const EdgeInsets.all(12),
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
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: AppColors.error),
                            ),
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
                              'Connect',
                              style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
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

  const _RecentHostTile({required this.host, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.history_rounded, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 10),
            Text(host,
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
