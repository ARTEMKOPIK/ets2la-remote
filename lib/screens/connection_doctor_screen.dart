/// Sequential port-probe diagnostic screen. Shown manually from the
/// Connect screen ("Connection doctor" button). Walks the user through
/// every port ETS2LA needs to be reachable on and tells them exactly
/// which one is blocked, plus offers a one-tap copy of the Windows
/// firewall rule that will open all four.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';

import '../services/port_probe_service.dart';
import '../theme/app_theme.dart';
import '../utils/toast.dart';

class ConnectionDoctorScreen extends StatefulWidget {
  const ConnectionDoctorScreen({
    super.key,
    required this.host,
    required this.portApi,
    required this.portViz,
    required this.portNav,
    required this.portPages,
  });

  final String? host;
  final int portApi;
  final int portViz;
  final int portNav;
  final int portPages;

  @override
  State<ConnectionDoctorScreen> createState() => _ConnectionDoctorScreenState();
}

class _ConnectionDoctorScreenState extends State<ConnectionDoctorScreen> {
  final TextEditingController _hostCtrl = TextEditingController();
  final List<_DoctorStep> _steps = [];
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _hostCtrl.text = widget.host ?? '';
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final host = _hostCtrl.text.trim();
    if (host.isEmpty) return;
    setState(() {
      _running = true;
      _steps
        ..clear()
        ..addAll([
          _DoctorStep(name: 'api', port: widget.portApi),
          _DoctorStep(name: 'viz', port: widget.portViz),
          _DoctorStep(name: 'nav', port: widget.portNav),
          _DoctorStep(name: 'pages', port: widget.portPages),
        ]);
    });
    for (int i = 0; i < _steps.length; i++) {
      final step = _steps[i];
      setState(() {
        _steps[i] = step.copyWith(running: true);
      });
      final report = await PortProbeService.probe(host, step.port);
      if (!mounted) return;
      setState(() {
        _steps[i] = step.copyWith(running: false, report: report);
      });
    }
    if (!mounted) return;
    setState(() => _running = false);
  }

  String _firewallCommand() {
    // Creates one PowerShell rule that opens every ETS2LA port in one go.
    // User copies → runs in an elevated PowerShell → reruns the doctor.
    final ports = [
      widget.portApi,
      widget.portViz,
      widget.portNav,
      widget.portPages,
    ].join(',');
    return 'New-NetFirewallRule -DisplayName "ETS2LA" -Direction Inbound '
        '-Action Allow -Protocol TCP -LocalPort $ports';
  }

  Future<void> _copyFirewall() async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _firewallCommand()));
    if (!mounted) return;
    AppToast.success(
      context,
      l10n?.firewallCommandCopied ?? 'Firewall command copied',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final anyBlocked = _steps.any(
      (s) => s.report?.result == ProbeResult.blocked,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.connectionDoctor ?? 'Connection doctor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n?.connectionDoctorHint ??
                'Probes every port and shows which one is blocked',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _hostCtrl,
            decoration: InputDecoration(
              labelText: l10n?.enterIp ?? 'Enter IP address',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _running ? null : _run,
              icon: _running
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.play_arrow_rounded),
              label: Text(l10n?.runDiagnostics ?? 'Run diagnostics'),
            ),
          ),
          if (_steps.isNotEmpty) ...[
            const SizedBox(height: 20),
            ..._steps.map((s) => _StepTile(step: s)),
          ],
          if (anyBlocked) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _copyFirewall,
              icon: const Icon(Icons.copy_rounded, color: AppColors.orange),
              label: Text(
                l10n?.copyFirewallCommand ??
                    'Copy Windows firewall command',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: SelectableText(
                _firewallCommand(),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DoctorStep {
  const _DoctorStep({
    required this.name,
    required this.port,
    this.running = false,
    this.report,
  });

  final String name;
  final int port;
  final bool running;
  final PortReport? report;

  _DoctorStep copyWith({bool? running, PortReport? report}) => _DoctorStep(
        name: name,
        port: port,
        running: running ?? this.running,
        report: report ?? this.report,
      );

  String label(AppLocalizations? l10n) {
    switch (name) {
      case 'api':
        return l10n?.doctorPingingApi(port) ?? 'API (port $port)';
      case 'viz':
        return l10n?.doctorOpeningViz(port) ??
            'Visualization WS (port $port)';
      case 'nav':
        return l10n?.doctorOpeningNav(port) ??
            'Navigation WS (port $port)';
      case 'pages':
        return l10n?.doctorOpeningPages(port) ?? 'Pages WS (port $port)';
      default:
        return 'Port $port';
    }
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.step});
  final _DoctorStep step;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    IconData icon;
    Color color;
    String status;
    if (step.running) {
      icon = Icons.more_horiz_rounded;
      color = AppColors.textSecondary;
      status = '…';
    } else if (step.report == null) {
      icon = Icons.circle_outlined;
      color = AppColors.textMuted;
      status = '';
    } else if (step.report!.result == ProbeResult.reachable) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      status = l10n?.doctorReachable ?? 'Reachable';
    } else {
      icon = Icons.cancel_rounded;
      color = AppColors.error;
      status = l10n?.doctorBlocked ?? 'Blocked';
    }
    // MergeSemantics so TalkBack reads the row as a single sentence
    // ("API port 37520, blocked") instead of icon / label / status as
    // three separate focus nodes. Colour + icon are the only
    // affordance for sighted users — this matches that for screen
    // readers.
    return MergeSemantics(
      child: Semantics(
        label: status.isEmpty
            ? step.label(l10n)
            : '${step.label(l10n)}, $status',
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              if (step.running)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.orange,
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.label(l10n),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (status.isNotEmpty)
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
