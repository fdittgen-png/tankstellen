import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/reference_vehicle_catalog_provider.dart';
import '../../domain/entities/reference_vehicle.dart';

/// Modal bottom sheet that lets the user pre-fill an empty
/// [EditVehicleScreen] form by picking from the bundled reference
/// catalog (#1372 phase 3).
///
/// The catalog ships ~50 popular EU passenger cars compiled from the
/// 2015-2024 new-car registration tables. Each entry carries the engine
/// quirks the OBD-II layer needs (volumetric efficiency, odometer PID
/// strategy) so users don't have to discover them by hand. Phase 1
/// (#1380) shipped the abstraction docs; phase 2 (#1398) grew the
/// catalog from 31 to 51 entries; this phase exposes a UI affordance.
///
/// UX:
/// - Opens via the static [show] helper which routes through
///   [showModalBottomSheet] with `isScrollControlled: true` so the sheet
///   can grow to ~85 % of the viewport.
/// - A search field at the top filters entries by `make + model +
///   generation` substring, case-insensitive. Empty search shows the
///   full catalog.
/// - Each list tile renders `make + model` as the primary line and
///   `generation · yearStart–yearEnd · displacementCc cc fuelType`
///   as the subtitle. Tap → [Navigator.pop] with the selected entry
///   as the result.
/// - A Cancel button at the bottom dismisses the sheet with a `null`
///   result. Drag-to-dismiss and scrim-tap also dismiss with `null`.
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  /// Case-insensitive substring filter on `make + model + generation`.
  ///
  /// 51 entries → trivial to filter on every keystroke. We deliberately
  /// don't debounce.
  List<ReferenceVehicle> _filter(List<ReferenceVehicle> all, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return all;
    return all.where((v) {
      final haystack =
          '${v.make} ${v.model} ${v.generation}'.toLowerCase();
      return haystack.contains(trimmed);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final catalogAsync = ref.watch(referenceVehicleCatalogProvider);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

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
              // Title row.
              Row(
                children: [
                  Icon(
                    Icons.directions_car_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l?.pickerButtonLabel ?? 'Pick from catalog',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Search field.
              TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText:
                      l?.pickerSearchHint ?? 'Search make or model',
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
              // Body — loading / error / list.
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
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                  data: (catalog) {
                    final filtered = _filter(catalog, _searchController.text);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l?.pickerEmptyResults ?? 'No matches',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final entry = filtered[i];
                        return _ReferenceVehicleTile(
                          entry: entry,
                          onTap: () => Navigator.of(context).pop(entry),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Cancel row.
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
}

/// One row in the [ReferenceVehiclePicker] list.
///
/// Title is `make model`; subtitle packs generation + production
/// window + displacement + fuelType into a single line.
class _ReferenceVehicleTile extends StatelessWidget {
  final ReferenceVehicle entry;
  final VoidCallback onTap;

  const _ReferenceVehicleTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final yearEnd = entry.yearEnd?.toString() ?? '';
    final yearRange = '${entry.yearStart}–$yearEnd';
    final subtitle =
        '${entry.generation} · $yearRange · ${entry.displacementCc}cc ${entry.fuelType}';
    return ListTile(
      title: Text('${entry.make} ${entry.model}'),
      subtitle: Text(subtitle),
      onTap: onTap,
      dense: true,
    );
  }
}
