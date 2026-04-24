/// Lets the user pick which dashboard cards are shown and in what
/// order. State is persisted to [AppSettings.dashboardLayout] as a
/// comma-separated list of card ids. An empty list means "use the
/// default layout", so a fresh install stays on the built-in order.
library;

import 'package:flutter/material.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Canonical card registry. When adding a new card to the dashboard,
/// declare it here — the Customize screen renders each entry, and the
/// [_DashboardTab] reads [dashboardCardIds] as the default ordering.
const List<({String id, String label})> dashboardCards = [
  (id: 'autopilot', label: 'Autopilot'),
  (id: 'gauge', label: 'Speed gauge'),
  (id: 'sparkline', label: 'Speed sparkline'),
  (id: 'pedals', label: 'Pedals'),
  (id: 'plugins', label: 'Plugins status'),
];

List<String> get dashboardCardIds =>
    [for (final c in dashboardCards) c.id];

class DashboardCustomizeScreen extends StatefulWidget {
  const DashboardCustomizeScreen({super.key});

  @override
  State<DashboardCustomizeScreen> createState() =>
      _DashboardCustomizeScreenState();
}

class _DashboardCustomizeScreenState extends State<DashboardCustomizeScreen> {
  late List<String> _order;
  late Set<String> _hidden;

  @override
  void initState() {
    super.initState();
    _loadFromSettings();
  }

  void _loadFromSettings() {
    final s = context.read<AppSettings>();
    final persisted = s.dashboardLayout;
    if (persisted.isEmpty) {
      _order = List.of(dashboardCardIds);
      _hidden = <String>{};
    } else {
      // Persisted entries can be "cardId" (shown) or "-cardId" (hidden).
      final shown = <String>[];
      final hidden = <String>{};
      final seen = <String>{};
      for (final raw in persisted) {
        final hiddenFlag = raw.startsWith('-');
        final id = hiddenFlag ? raw.substring(1) : raw;
        if (!dashboardCardIds.contains(id)) continue;
        seen.add(id);
        if (hiddenFlag) {
          hidden.add(id);
        }
        shown.add(id);
      }
      // Append any cards added after the user persisted their order so
      // new features show up automatically instead of being missing.
      for (final c in dashboardCardIds) {
        if (!seen.contains(c)) shown.add(c);
      }
      _order = shown;
      _hidden = hidden;
    }
  }

  void _save() {
    final encoded = <String>[
      for (final id in _order) _hidden.contains(id) ? '-$id' : id,
    ];
    context.read<AppSettings>().setDashboardLayout(encoded);
  }

  void _resetDefault() {
    setState(() {
      _order = List.of(dashboardCardIds);
      _hidden = <String>{};
    });
    context.read<AppSettings>().setDashboardLayout(const <String>[]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.customizeDashboard ?? 'Customize dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: l10n?.resetToDefault ?? 'Reset to default',
            onPressed: _resetDefault,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              l10n?.customizeDashboardHint ??
                  'Drag to reorder. Toggle the switch to hide a card.',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _order.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final id = _order.removeAt(oldIndex);
                  _order.insert(newIndex, id);
                });
                _save();
              },
              itemBuilder: (ctx, i) {
                final id = _order[i];
                final label = dashboardCards
                    .firstWhere((c) => c.id == id, orElse: () => (id: id, label: id))
                    .label;
                final visible = !_hidden.contains(id);
                return Container(
                  key: ValueKey(id),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: i,
                      child: const Icon(
                        Icons.drag_handle_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        color: visible
                            ? AppColors.textPrimary
                            : AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Switch(
                      value: visible,
                      onChanged: (v) {
                        setState(() {
                          if (v) {
                            _hidden.remove(id);
                          } else {
                            _hidden.add(id);
                          }
                        });
                        _save();
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
