import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../vehicle/domain/entities/vehicle_profile.dart';
import '../../../vehicle/providers/vehicle_providers.dart';
import '../../data/obd2/obd2_connection_errors.dart';
import '../../data/trip_history_repository.dart';
import '../../providers/trip_history_provider.dart';
import '../../providers/trip_recording_provider.dart';
import '../screens/trip_recording_screen.dart';
import 'obd2_adapter_picker.dart';

/// Trajets tab body on the Consumption screen (#889).
///
/// Top of the tab shows a primary "Start recording" CTA that kicks
/// off [TripRecording.startTrip]. The rest is a list of past trips
/// from [tripHistoryListProvider], filtered to the active vehicle
/// when one is available (otherwise every logged trip is shown).
///
/// Tap a row -> pushes `/trip/:id` (placeholder detail screen lives
/// in #890's full impl; #889 lands the route so the tap works).
class TrajetsTab extends ConsumerStatefulWidget {
  /// Id of the active vehicle. When non-null, the trip list is
  /// filtered down to trips recorded against this vehicle. When null
  /// (no active vehicle), the list still renders every persisted
  /// trip — avoids an empty Trajets tab just because the user hasn't
  /// flipped their active vehicle.
  final String? vehicleId;

  const TrajetsTab({super.key, this.vehicleId});

  @override
  ConsumerState<TrajetsTab> createState() => _TrajetsTabState();
}

class _TrajetsTabState extends ConsumerState<TrajetsTab> {
  bool _starting = false;

  Future<void> _onStartRecording() async {
    if (_starting) return;
    setState(() => _starting = true);
    try {
      final notifier = ref.read(tripRecordingProvider.notifier);
      final outcome = await notifier.startTrip();
      if (!mounted) return;
      if (outcome == StartTripOutcome.alreadyActive) {
        // A trajet is already running in the background — just jump
        // into the recording screen without re-connecting.
        await Navigator.of(context).push<TripSaveResult?>(
          MaterialPageRoute(
            builder: (_) => const TripRecordingScreen(),
          ),
        );
        return;
      }
      // `started` would only happen if we'd handed a service in — we
      // didn't. `needsPicker` is the expected path here: surface the
      // picker, then hand the resulting service back to the provider
      // (same pattern as AddFillUpScreen).
      final service = await showObd2AdapterPicker(context);
      if (service == null || !mounted) return;
      await notifier.start(service);
      if (!mounted) return;
      await Navigator.of(context).push<TripSaveResult?>(
        MaterialPageRoute(
          builder: (_) => const TripRecordingScreen(),
        ),
      );
    } on Obd2ConnectionError catch (e, st) { // ignore: unused_catch_stack
      if (mounted) SnackBarHelper.showError(context, e.message);
    } catch (e, st) {
      debugPrint('TrajetsTab._onStartRecording: $e\n$st');
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final trips = ref.watch(tripHistoryListProvider);
    final vehicles = ref.watch(vehicleProfileListProvider);
    final activeVehicle = ref.watch(activeVehicleProfileProvider);
    // Filter to the active vehicle when one is set (#889). Keep every
    // trip when there is no active vehicle so the tab isn't silently
    // empty just because the profile selector hasn't been used.
    final filteredUnsorted = widget.vehicleId == null
        ? trips.toList(growable: false)
        : trips
            .where((t) =>
                t.vehicleId == null || t.vehicleId == widget.vehicleId)
            .toList(growable: false);
    // Defensive sort: `TripHistoryRepository.loadAll` already returns
    // newest-first, but we don't want to assume the provider was
    // populated by the repo path (tests, future sync sources). Sort
    // by `startedAt` descending here so the UI contract is tab-level.
    final filtered = List<TripHistoryEntry>.from(filteredUnsorted)
      ..sort((a, b) {
        final ax = a.summary.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bx = b.summary.startedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bx.compareTo(ax);
      });

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: FilledButton.icon(
        key: const Key('trajets_start_recording_button'),
        onPressed: _starting ? null : _onStartRecording,
        icon: const Icon(Icons.fiber_manual_record),
        label: Text(
          l?.trajetsStartRecordingButton ?? 'Start recording',
        ),
      ),
    );

    if (filtered.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          Expanded(
            child: EmptyState(
              key: const Key('trajets_empty_state'),
              icon: Icons.route_outlined,
              title: l?.trajetsEmptyStateTitle ?? 'No trips yet',
              subtitle: l?.trajetsEmptyStateBody ??
                  'Tap Start recording to begin logging your drives.',
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        Expanded(
          child: ListView.builder(
            key: const Key('trajets_list'),
            padding: EdgeInsets.only(
              top: 4,
              bottom: 16 + MediaQuery.of(context).viewPadding.bottom,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final entry = filtered[index];
              // Resolve the per-trip vehicle for fuel-family display.
              // Fall back to the active vehicle (most likely the
              // right one) when the trip pre-dates the vehicleId
              // tagging that landed alongside #889.
              final vehicle = entry.vehicleId == null
                  ? activeVehicle
                  : vehicles
                      .where((v) => v.id == entry.vehicleId)
                      .firstOrNull ??
                      activeVehicle;
              return _TrajetRow(
                entry: entry,
                vehicle: vehicle,
                l: l,
                theme: theme,
                onTap: () => context.push('/trip/${entry.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// One row in the Trajets list (#889). Shows date/time + three chips
/// for distance, duration, and average consumption.
class _TrajetRow extends StatelessWidget {
  final TripHistoryEntry entry;
  final VehicleProfile? vehicle;
  final AppLocalizations? l;
  final ThemeData theme;
  final VoidCallback onTap;

  const _TrajetRow({
    required this.entry,
    required this.vehicle,
    required this.l,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = entry.summary;
    final startedAt = s.startedAt;
    final durationSec = startedAt != null && s.endedAt != null
        ? s.endedAt!.difference(startedAt).inSeconds
        : null;
    final durationMinutes = durationSec == null ? null : durationSec ~/ 60;
    final isEv = vehicle?.type == VehicleType.ev;
    // Placeholder kWh/100 km formula for EV trips — full EV telemetry
    // lands with the OBD2 EV PID set. Until then, treat the combustion
    // path as the canonical avg, and just swap the unit label for EV
    // vehicles so the UI reads correctly when an EV trip IS logged.
    final avgUnit = isEv ? 'kWh/100 km' : 'L/100 km';

    return Card(
      key: ValueKey('trajet-${entry.id}'),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.route, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startedAt == null
                          ? (l?.tripHistoryUnknownDate ?? 'Unknown date')
                          : _fmtDate(startedAt),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Chip(
                          icon: Icons.straighten,
                          text: l?.trajetsRowDistance(
                                s.distanceKm.toStringAsFixed(1),
                              ) ??
                              '${s.distanceKm.toStringAsFixed(1)} km',
                        ),
                        if (durationMinutes != null && durationMinutes > 0)
                          _Chip(
                            icon: Icons.timer,
                            text: l?.trajetsRowDuration(
                                  durationMinutes.toString(),
                                ) ??
                                '$durationMinutes min',
                          ),
                        if (s.avgLPer100Km != null)
                          _Chip(
                            icon: Icons.eco,
                            text: l?.trajetsRowAvgConsumption(
                                  s.avgLPer100Km!.toStringAsFixed(1),
                                  avgUnit,
                                ) ??
                                '${s.avgLPer100Km!.toStringAsFixed(1)} $avgUnit',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Chip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
