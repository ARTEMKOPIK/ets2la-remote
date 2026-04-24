/// Browsable history of finished driving sessions. Shows distance,
/// duration, average speed, autopilot utilisation and per-session
/// disengagement counts. Reads from [TripLogService.loadTrips].

import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';

import '../models/trip_entry.dart';
import '../services/trip_log_service.dart';
import '../theme/app_theme.dart';

class TripLogScreen extends StatefulWidget {
  const TripLogScreen({super.key});

  @override
  State<TripLogScreen> createState() => _TripLogScreenState();
}

class _TripLogScreenState extends State<TripLogScreen> {
  late Future<List<TripEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = TripLogService.loadTrips();
  }

  Future<void> _reload() async {
    setState(() {
      _future = TripLogService.loadTrips();
    });
    await _future;
  }

  Future<void> _confirmClear() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.tripLogClearTitle ?? 'Clear trip history?'),
        content: Text(l10n?.tripLogClearBody ??
            'This removes all saved trips from this device. The action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n?.clear ?? 'Clear',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await TripLogService.clear();
      if (!mounted) return;
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.tripLogTitle ?? 'Trip log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: l10n?.clear ?? 'Clear',
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: FutureBuilder<List<TripEntry>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            );
          }
          final trips = snap.data ?? const <TripEntry>[];
          if (trips.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n?.tripLogEmpty ??
                      'No trips yet. Drive for a minute with ETS2LA connected '
                          'and they\'ll show up here.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            color: AppColors.orange,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: trips.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                if (i == 0) {
                  return _TotalsCard(trips: trips);
                }
                return _TripCard(entry: trips[i - 1]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.trips});
  final List<TripEntry> trips;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final totalKm = trips.fold<double>(0, (sum, t) => sum + t.distanceKm);
    final totalSeconds = trips.fold<int>(
      0,
      (sum, t) => sum + t.duration.inSeconds,
    );
    final autopilotSeconds = trips.fold<int>(
      0,
      (sum, t) => sum + t.autopilotSeconds,
    );
    final autopilotPct = totalSeconds == 0
        ? 0.0
        : (autopilotSeconds / totalSeconds * 100);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.tripLogTotalsTitle ?? 'All-time totals',
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              letterSpacing: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TotalCell(
                  label: l10n?.distance ?? 'Distance',
                  value: '${totalKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: _TotalCell(
                  label: l10n?.drivingTime ?? 'Driving time',
                  value: _formatDuration(Duration(seconds: totalSeconds)),
                ),
              ),
              Expanded(
                child: _TotalCell(
                  label: l10n?.autopilotShare ?? 'Autopilot',
                  value: '${autopilotPct.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCell extends StatelessWidget {
  const _TotalCell({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.entry});
  final TripEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final duration = entry.duration;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDate(entry.startedAt),
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _TripMetric(
                label: l10n?.distance ?? 'Distance',
                value: '${entry.distanceKm.toStringAsFixed(1)} km',
              ),
              _TripMetric(
                label: l10n?.avgSpeed ?? 'Avg',
                value: '${entry.avgSpeedKmh.round()} km/h',
              ),
              _TripMetric(
                label: l10n?.maxSpeed ?? 'Max',
                value: '${entry.maxSpeedKmh.round()} km/h',
              ),
              _TripMetric(
                label: l10n?.autopilotShare ?? 'Autopilot',
                value:
                    '${(entry.autopilotFraction * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          if (entry.disengagements > 0) ...[
            const SizedBox(height: 8),
            Text(
              l10n?.disengagements(entry.disengagements) ??
                  '${entry.disengagements} disengagements',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final local = dt.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return 'Today, $hh:$mm';
  }
  final dd = local.day.toString().padLeft(2, '0');
  final mon = local.month.toString().padLeft(2, '0');
  return '$dd.$mon ${local.year} $hh:$mm';
}
