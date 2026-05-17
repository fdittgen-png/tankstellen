import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/reference_vehicle_catalog_provider.dart';
import '../../domain/entities/reference_vehicle.dart';

/// Modal bottom sheet that lets the user pre-fill an empty
/// [EditVehicleScreen] form by picking from the bundled reference
/// catalog (#1372 phase 3; rebuilt for scale in #1643).
///
/// The catalog grew to ~250 entries (epic #1640), so a flat scrolling
/// list no longer scales. The picker now offers a **make → model →
/// generation drill-down**: the user taps a make to see its models,
/// a model to see its generations, and a generation to select it.
/// Any catalog entry is therefore reachable in three taps regardless
/// of catalog size.
///
/// A debounced type-ahead search sits above the drill-down: while the
/// search box is non-empty it overrides the drill-down with a flat
/// `make + model + generation` substring match across the whole
/// catalog; clearing it returns to the drill-down at its current level.
///
/// UX:
/// - Opens via [show] through [showModalBottomSheet] with
///   `isScrollControlled: true` so the sheet can grow to ~85 % height.
/// - Tap a generation → [Navigator.pop] with the selected entry.
/// - Cancel / drag-to-dismiss / scrim-tap dismiss with a `null` result.
///
/// The picker MUST NOT be shown while editing an existing vehicle —
/// callers gate visibility on "create mode" so the user's tweaks are
/// never silently overwritten.
class ReferenceVehiclePicker extends ConsumerStatefulWidget {
  const ReferenceVehiclePicker({super.key});

  /// Launch the picker. Resolves to the picked [ReferenceVehicle], or
  /// `null` when the user dismisses the sheet without choosing.
  static Future<ReferenceVehicle?> show(BuildContext context) {
    return showModalBottomSheet<ReferenceVehicle>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ReferenceVehiclePicker(),
    );
  }

  @override
  ConsumerState<ReferenceVehiclePicker> createState() =>
      _ReferenceVehiclePickerState();
}

class _ReferenceVehiclePickerState
    extends ConsumerState<ReferenceVehiclePicker> {
  final TextEditingController _searchController = TextEditingController();

  /// Debounce window for the type-ahead. The catalog is ~250 entries —
  /// trivially filterable — but debouncing still avoids rebuilding the
  /// list on every keystroke when the user types fast on a long query.
  static const _debounce = Duration(milliseconds: 250);
  Timer? _debounceTimer;

  /// The committed (post-debounce) search query.
  String _query = '';

  /// Drill-down cursor. Both null → make list; make set → model list;
  /// both set → generation list.
  String? _make;
  String? _model;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () {
      if (!mounted) return;
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  /// Steps one level back up the drill-down. Returns false when already
  /// at the root (the caller then has nothing to pop).
  bool _drillUp() {
    if (_model != null) {
      setState(() => _model = null);
      return true;
    }
    if (_make != null) {
      setState(() => _make = null);
      return true;
    }
    return false;
  }

  /// Flat substring match across the whole catalog — used while the
  /// search box is non-empty.
  List<ReferenceVehicle> _search(List<ReferenceVehicle> all) {
    if (_query.isEmpty) return const [];
    return all.where((v) {
      final haystack = '${v.make} ${v.model} ${v.generation}'.toLowerCase();
      return haystack.contains(_query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(referenceVehicleCatalogProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
    final searching = _query.isNotEmpty;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title row — a back button appears once the user has
              // drilled into a make (and is not searching).
              Row(
                children: [
                  if (!searching && _make != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      tooltip: l?.tooltipBack ?? 'Back',
                      onPressed: _drillUp,
                    )
                  else
                    Icon(Icons.directions_car_outlined,
                        color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _breadcrumb(l),
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l?.pickerSearchHint ?? 'Search make or model',
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          tooltip: l?.pickerCancel ?? 'Cancel',
                          onPressed: () => _searchController.clear(),
                        ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: catalogAsync.when(
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(l?.pickerLoading ?? 'Loading catalog…'),
                      ],
                    ),
                  ),
                  error: (error, _) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Error: $error',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ),
                  data: (catalog) => searching
                      ? _buildSearchResults(catalog, l, theme)
                      : _buildDrillDown(catalog, l, theme),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l?.pickerCancel ?? 'Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Title text — plain label at the root, else the drill-down path.
  String _breadcrumb(AppLocalizations? l) {
    if (_make == null) return l?.pickerButtonLabel ?? 'Pick from catalog';
    if (_model == null) return _make!;
    return '$_make · $_model';
  }

  Widget _emptyState(AppLocalizations? l, ThemeData theme) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l?.pickerEmptyResults ?? 'No matches',
              style: theme.textTheme.bodyMedium),
        ),
      );

  Widget _buildSearchResults(
      List<ReferenceVehicle> catalog, AppLocalizations? l, ThemeData theme) {
    final results = _search(catalog);
    if (results.isEmpty) return _emptyState(l, theme);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: results.length,
      itemBuilder: (context, i) => _GenerationTile(
        entry: results[i],
        showModel: true,
        onTap: () => Navigator.of(context).pop(results[i]),
      ),
    );
  }

  Widget _buildDrillDown(
      List<ReferenceVehicle> catalog, AppLocalizations? l, ThemeData theme) {
    // Level 3 — generations of the selected make + model.
    if (_make != null && _model != null) {
      final generations = catalog
          .where((v) => v.make == _make && v.model == _model)
          .toList()
        ..sort((a, b) => b.yearStart.compareTo(a.yearStart));
      if (generations.isEmpty) return _emptyState(l, theme);
      return ListView.builder(
        shrinkWrap: true,
        itemCount: generations.length,
        itemBuilder: (context, i) => _GenerationTile(
          entry: generations[i],
          showModel: false,
          onTap: () => Navigator.of(context).pop(generations[i]),
        ),
      );
    }

    // Level 2 — models of the selected make.
    if (_make != null) {
      final models = <String, int>{};
      for (final v in catalog) {
        if (v.make == _make) {
          models[v.model] = (models[v.model] ?? 0) + 1;
        }
      }
      final sorted = models.keys.toList()..sort();
      return ListView.builder(
        shrinkWrap: true,
        itemCount: sorted.length,
        itemBuilder: (context, i) => _GroupTile(
          label: sorted[i],
          count: models[sorted[i]]!,
          onTap: () => setState(() => _model = sorted[i]),
        ),
      );
    }

    // Level 1 — makes.
    final makes = <String, int>{};
    for (final v in catalog) {
      makes[v.make] = (makes[v.make] ?? 0) + 1;
    }
    final sorted = makes.keys.toList()..sort();
    return ListView.builder(
      shrinkWrap: true,
      itemCount: sorted.length,
      itemBuilder: (context, i) => _GroupTile(
        label: sorted[i],
        count: makes[sorted[i]]!,
        onTap: () => setState(() => _make = sorted[i]),
      ),
    );
  }
}

/// A drill-down group row (a make or a model) with its entry count and
/// a trailing chevron.
class _GroupTile extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onTap;

  const _GroupTile(
      {required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$count',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
      dense: true,
    );
  }
}

/// A selectable leaf row — one catalog generation.
///
/// In the drill-down the make + model are already in the breadcrumb so
/// only the generation shows; in flat search results [showModel] adds
/// the `make model` line so the row is self-describing.
class _GenerationTile extends StatelessWidget {
  final ReferenceVehicle entry;
  final bool showModel;
  final VoidCallback onTap;

  const _GenerationTile(
      {required this.entry, required this.showModel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final yearRange = '${entry.yearStart}–${entry.yearEnd?.toString() ?? ''}';
    final spec =
        '$yearRange · ${entry.displacementCc}cc ${entry.fuelType}';
    return ListTile(
      title: Text(showModel
          ? '${entry.make} ${entry.model} · ${entry.generation}'
          : entry.generation),
      subtitle: Text(spec),
      onTap: onTap,
      dense: true,
    );
  }
}
