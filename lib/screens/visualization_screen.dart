import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../providers/connection_provider.dart';
import '../providers/telemetry_provider.dart';
import '../providers/settings_provider.dart';
import '../services/local_server.dart';
import '../theme/app_theme.dart';

class VisualizationScreen extends StatefulWidget {
  const VisualizationScreen({super.key});

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  InAppWebViewController? _ctrl;
  bool _webViewLoading = true;
  bool _injected = false;
  bool _serverReady = false;
  bool _fullscreen = false;
  bool _darkTheme = true;
  String _statusText = 'Preparing Unity...';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _ensureServer();
  }

  Future<void> _ensureServer() async {
    final l10n = AppLocalizations.of(context);
    if (LocalUnityServer.instance.isReady) {
      if (mounted) setState(() => _serverReady = true);
      return;
    }
    try {
      await LocalUnityServer.instance.ensureStarted(
        onProgress: (msg) {
          if (mounted) {
            String localizedMsg = msg;
            if (msg.startsWith('Updating')) {
              final file = msg.replaceAll('Updating ', '').replaceAll('...', '');
              localizedMsg = l10n?.updatingFile(file) ?? msg;
            } else if (msg == 'Starting local server...') {
              localizedMsg = l10n?.startingLocalServer ?? msg;
            }
            setState(() => _statusText = localizedMsg);
          }
        },
      );
      if (mounted) setState(() => _serverReady = true);
    } catch (e) {
      if (mounted) setState(() => _errorText = 'Error: $e');
    }
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  void _toggleTheme() {
    setState(() => _darkTheme = !_darkTheme);
    final theme = _darkTheme ? 'dark' : 'light';
    _ctrl?.evaluateJavascript(
      source: "if(typeof setTheme==='function') setTheme('$theme');",
    );
  }

  void _zoomIn() {
    _ctrl?.evaluateJavascript(source: 'if(typeof zoomIn==="function") zoomIn(); else window._zoom = (window._zoom||1) - 0.15;');
  }

  void _zoomOut() {
    _ctrl?.evaluateJavascript(source: 'if(typeof zoomOut==="function") zoomOut(); else window._zoom = (window._zoom||1) + 0.15;');
  }

  void _resetCamera() {
    _ctrl?.evaluateJavascript(source: 'if(typeof resetCamera==="function") resetCamera();');
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final host = context.watch<ConnectionProvider>().currentHost;
    final telem = context.watch<TelemetryProvider>();
    final conn = context.watch<ConnectionProvider>();
    final settings = context.watch<AppSettings>();

    if (!_serverReady) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.view3d ?? '3D View', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppColors.orange),
              const SizedBox(height: 20),
              Text(_statusText == 'Preparing Unity...' ? (AppLocalizations.of(context)?.preparingUnity ?? 'Preparing Unity...') : _statusText, style: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)?.firstLaunchHint ?? 'First launch only ~5s', style: TextStyle(fontFamily: 'Roboto', color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    if (_errorText != null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)?.view3d ?? '3D View', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600))),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_errorText!, style: TextStyle(fontFamily: 'Roboto', color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () { setState(() { _errorText = null; }); _ensureServer(); }, child: Text(AppLocalizations.of(context)?.retry ?? 'Retry')),
            ],
          ),
        ),
      );
    }

    final body = Stack(
      children: [
        // ── Unity WebView ──
        RepaintBoundary(
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('http://127.0.0.1:${LocalUnityServer.port}/index.html')),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              useHybridComposition: false,
              mediaPlaybackRequiresUserGesture: false,
              hardwareAcceleration: true,
              allowContentAccess: true,
              allowFileAccess: true,
              disableVerticalScroll: true,
              disableHorizontalScroll: true,
            ),
            onWebViewCreated: (c) => _ctrl = c,
            onLoadStart: (_, __) => setState(() { _webViewLoading = true; _injected = false; }),
            onLoadStop: (controller, url) async {
              setState(() => _webViewLoading = false);
              if (!_injected) {
                _injected = true;
                await Future.delayed(const Duration(milliseconds: 600));
                // Apply saved theme
                final theme = settings.vizDarkTheme ? 'dark' : 'light';
                setState(() => _darkTheme = settings.vizDarkTheme);
                await controller.evaluateJavascript(
                  source: "if(typeof setTheme==='function') setTheme('$theme');",
                );
                // Auto-connect if enabled
                if (settings.vizAutoConnect && host.isNotEmpty) {
                  await controller.evaluateJavascript(
                    source: "if(typeof setAutoConnectIP==='function') setAutoConnectIP('$host');",
                  );
                }
              }
            },
            // debugPrint('[3DView] ${msg.message}'), // removed for production
          ),
        ),

        // ── Top status bar ──
        Positioned(
          top: 12, left: 12, right: 12,
          child: Row(
            children: [
              // Connection status
              _GlassChip(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7, height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: conn.isConnected ? AppColors.success : AppColors.error,
                        boxShadow: [BoxShadow(
                          color: (conn.isConnected ? AppColors.success : AppColors.error).withOpacity(0.6),
                          blurRadius: 6,
                        )],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      conn.isConnected ? host : (AppLocalizations.of(context)?.reconnecting ?? 'Reconnecting...'),
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Loading indicator
              if (_webViewLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange)),
                ),
            ],
          ),
        ),

        // ── Mini HUD (speed + autopilot) ──
        Positioned(
          bottom: 80, left: 12,
          child: _GlassChip(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed_rounded, size: 12, color: AppColors.orange),
                    const SizedBox(width: 4),
                    Text(
                      '${(settings.speedUnit == SpeedUnit.kmh ? telem.truckState.speedKmh : telem.truckState.speedKmh * 0.621371).toStringAsFixed(0)} ${settings.speedUnit == SpeedUnit.kmh ? "km/h" : "mph"}',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: telem.autopilotStatus.steeringEnabled ? AppColors.success : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      telem.autopilotStatus.steeringEnabled 
                        ? (AppLocalizations.of(context)?.autopilotOn ?? 'Autopilot ON') 
                        : (AppLocalizations.of(context)?.autopilotOff ?? 'Autopilot OFF'),
                      style: TextStyle(fontFamily: 'Roboto', 
                        fontSize: 11,
                        color: telem.autopilotStatus.steeringEnabled ? AppColors.success : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Right side controls ──
        Positioned(
          right: 12, bottom: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fullscreen
              _CircleButton(
                icon: _fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                onTap: _toggleFullscreen,
              ),
              const SizedBox(height: 8),
              // Theme toggle
              _CircleButton(
                icon: _darkTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: _toggleTheme,
              ),
              const SizedBox(height: 8),
              // Zoom in
              _CircleButton(icon: Icons.add_rounded, onTap: _zoomIn),
              const SizedBox(height: 8),
              // Reset camera
              _CircleButton(icon: Icons.my_location_rounded, onTap: _resetCamera),
              const SizedBox(height: 8),
              // Zoom out
              _CircleButton(icon: Icons.remove_rounded, onTap: _zoomOut),
            ],
          ),
        ),
      ],
    );

    // Fullscreen — no AppBar / bottom bar
    if (_fullscreen) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.view3d ?? '3D View', style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () { _injected = false; _ctrl?.reload(); },
          ),
        ],
      ),
      body: body,
    );
  }
}

// ── Glass chip widget ─────────────────────────────────────────────────────────
class _GlassChip extends StatelessWidget {
  final Widget child;
  const _GlassChip({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xCC141414), // semi-transparent
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: child,
    );
  }
}

// ── Circle button widget ──────────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: const Color(0xCC141414),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, size: 20, color: AppColors.textSecondary),
      ),
    );
  }
}
