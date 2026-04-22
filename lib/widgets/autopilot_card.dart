import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../theme/app_theme.dart';


typedef AsyncCallback = Future<void> Function();

class AutopilotCard extends StatefulWidget {
  final bool steeringEnabled;
  final bool accEnabled;
  final AsyncCallback? onToggleSteering;
  final AsyncCallback? onToggleAcc;

  const AutopilotCard({
    super.key,
    required this.steeringEnabled,
    required this.accEnabled,
    this.onToggleSteering,
    this.onToggleAcc,
  });

  @override
  State<AutopilotCard> createState() => _AutopilotCardState();
}

class _AutopilotCardState extends State<AutopilotCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  bool _steeringLoading = false;
  bool _accLoading = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pulseAnim = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Only animate when steering is active
    if (widget.steeringEnabled) _pulseCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(AutopilotCard old) {
    super.didUpdateWidget(old);
    if (widget.steeringEnabled && !old.steeringEnabled) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.steeringEnabled && old.steeringEnabled) {
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSteering() async {
    if (_steeringLoading) return;
    HapticFeedback.mediumImpact();
    setState(() => _steeringLoading = true);
    try {
      await widget.onToggleSteering?.call();
    } finally {
      if (mounted) setState(() => _steeringLoading = false);
    }
  }

  Future<void> _handleAcc() async {
    if (_accLoading) return;
    HapticFeedback.lightImpact();
    setState(() => _accLoading = true);
    try {
      await widget.onToggleAcc?.call();
    } finally {
      if (mounted) setState(() => _accLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.steeringEnabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C0E00), Color(0xFF2E1600), Color(0xFF1A0B00)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF141414), Color(0xFF1A1A1A)],
              ),
        border: Border.all(
          color: isActive
              ? AppColors.orange.withOpacity(0.45)
              : AppColors.surfaceBorder,
          width: 1.5,
        ),
        boxShadow: isActive
            ? [BoxShadow(
                color: AppColors.orange.withOpacity(0.18),
                blurRadius: 24, spreadRadius: 2)]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: isActive ? _pulseAnim.value : 1.0,
                    child: child,
                  ),
                  child: Container(
                    width: 9, height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive ? AppColors.success : AppColors.textMuted,
                      boxShadow: isActive
                          ? [BoxShadow(
                              color: AppColors.success.withOpacity(0.6),
                              blurRadius: 8)]
                          : [],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'AUTOPILOT',
                  style: TextStyle(fontFamily: 'Roboto', 
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary, letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                _StatusBadge(active: isActive),
              ],
            ),
            const SizedBox(height: 16),

            // Main toggle row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive 
                          ? (AppLocalizations.of(context)?.enabled ?? 'Active') 
                          : (AppLocalizations.of(context)?.disabled ?? 'Inactive'),
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: 26, fontWeight: FontWeight.w700,
                          color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isActive 
                          ? (AppLocalizations.of(context)?.steeringTheTruck ?? 'Steering the truck') 
                          : (AppLocalizations.of(context)?.manualControl ?? 'Manual control'),
                        style: TextStyle(fontFamily: 'Roboto', 
                          fontSize: 13, color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Big toggle button
                GestureDetector(
                  onTap: _handleSteering,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 72, height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      color: isActive ? AppColors.orange : AppColors.surfaceElevated,
                      border: Border.all(
                        color: isActive
                            ? AppColors.orange
                            : AppColors.surfaceBorder,
                        width: 1.5,
                      ),
                      boxShadow: isActive
                          ? [BoxShadow(
                              color: AppColors.orange.withOpacity(0.35),
                              blurRadius: 10)]
                          : [],
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: isActive
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _steeringLoading
                            ? SizedBox(
                                width: 28, height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isActive ? Colors.white : AppColors.orange,
                                ),
                              )
                            : Container(
                                width: 30, height: 30,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: Icon(
                                  isActive
                                      ? Icons.check_rounded
                                      : Icons.power_settings_new_rounded,
                                  size: 16,
                                  color: isActive
                                      ? AppColors.orange
                                      : AppColors.textMuted,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(color: AppColors.surfaceBorder.withOpacity(0.6)),
            const SizedBox(height: 10),

            // ACC row
            GestureDetector(
              onTap: _handleAcc,
              child: Row(
                children: [
                  Container(
                    width: 34, height: 34,
                    decoration: BoxDecoration(
                      color: widget.accEnabled
                          ? AppColors.orangeGlow
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.speed_rounded,
                      size: 18,
                      color: widget.accEnabled
                          ? AppColors.orange
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.adaptiveCruiseControl ?? 'Adaptive Cruise Control',
                          style: TextStyle(fontFamily: 'Roboto', 
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          widget.accEnabled 
                            ? (AppLocalizations.of(context)?.enabled ?? 'Active') 
                            : (AppLocalizations.of(context)?.disabled ?? 'Inactive'),
                          style: TextStyle(fontFamily: 'Roboto', 
                            fontSize: 11,
                            color: widget.accEnabled
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Small ACC toggle
                  _accLoading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 46, height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            color: widget.accEnabled
                                ? AppColors.orange
                                : AppColors.surfaceElevated,
                            border: Border.all(
                              color: widget.accEnabled
                                  ? AppColors.orange
                                  : AppColors.surfaceBorder,
                            ),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: widget.accEnabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                width: 20, height: 20,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.successDim : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? AppColors.success.withOpacity(0.4)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Text(
        active ? 'ON' : 'OFF',
        style: TextStyle(fontFamily: 'Roboto', 
          fontSize: 11, fontWeight: FontWeight.w700,
          color: active ? AppColors.success : AppColors.textMuted,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}
