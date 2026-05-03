import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/catalog_reresolve_detector.dart';
import '../../providers/catalog_reresolve_provider.dart';

/// Surfaces the one-time #1396 diesel-mismatch snackbar.
///
/// Watches [catalogReresolveCandidatesProvider]; on the first build
/// where a candidate is available, schedules a post-frame snackbar
/// for the first pending vehicle, persists the per-vehicle "already
/// nudged" flag, then invalidates the provider so the next pending
/// vehicle (if any) can take its turn on a subsequent rebuild.
///
/// This widget is intended to be mounted high in the tree (next to
/// the navigation shell) and does NOT render anything itself — it
/// returns the wrapped [child] verbatim. A separate host keeps the
/// snackbar logic out of the shell widget so the shell stays focused
/// on navigation and the nudge stays unit-testable.
class CatalogReresolveSnackbarHost extends ConsumerStatefulWidget {
  /// Subtree the host wraps. Returned verbatim from `build`.
  final Widget child;

  const CatalogReresolveSnackbarHost({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<CatalogReresolveSnackbarHost> createState() =>
      _CatalogReresolveSnackbarHostState();
}

class _CatalogReresolveSnackbarHostState
    extends ConsumerState<CatalogReresolveSnackbarHost> {
  /// Vehicles we've already surfaced a snackbar for in this widget's
  /// lifetime. The Hive flag is the persistent gate; this in-memory
  /// set guards against firing twice in a single launch when the
  /// provider rebuilds between flag write and provider invalidation.
  final Set<String> _surfacedThisSession = <String>{};

  @override
  Widget build(BuildContext context) {
    final asyncCandidates = ref.watch(catalogReresolveCandidatesProvider);

    asyncCandidates.whenData((candidates) {
      if (candidates.isEmpty) return;
      final next = candidates.firstWhere(
        (c) => !_surfacedThisSession.contains(c.vehicleId),
        orElse: () => const _SentinelCandidate(),
      );
      if (next.vehicleId.isEmpty) return;
      // Mark immediately so a synchronous rebuild during the
      // post-frame schedule doesn't double-fire for the same vehicle.
      _surfacedThisSession.add(next.vehicleId);

      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _surfaceSnackbar(next);
      });
    });

    return widget.child;
  }

  void _surfaceSnackbar(CatalogReresolveCandidate candidate) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final makeModel =
        '${candidate.make} ${candidate.model}'.trim();
    final message = l10n != null
        ? l10n.catalogReresolveSnackbarMessage(
            makeModel.isEmpty ? candidate.vehicleId : makeModel,
          )
        : 'Your $makeModel is marked as diesel but matches a '
            'petrol catalog entry. Tap to update.';
    final action = l10n?.catalogReresolveSnackbarAction ?? 'Update';

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: action,
          onPressed: () {
            // GoRouter is wired at the app level — `context.go` falls
            // through to the global router. The vehicle-edit route
            // expects the vehicle id as `extra` (see profile_routes.dart).
            try {
              GoRouter.of(context)
                  .push('/vehicles/edit', extra: candidate.vehicleId);
            } catch (_) {
              // Best-effort — if the router isn't available (widget
              // tests without a router) we still want the flag write
              // below to fire so the nudge does not loop.
            }
          },
        ),
      ),
    );

    // Persist the per-vehicle Hive flag so the snackbar never fires
    // again for this vehicle. Done after `showSnackBar` so a failure
    // in the messenger doesn't leave the user permanently un-
    // nudgeable.
    Future<void>(() async {
      try {
        await markCatalogReresolveSuggested(ref, candidate.vehicleId);
      } finally {
        // Force the provider to drop this candidate from its list so
        // the next pending vehicle can take its turn on the next
        // build.
        ref.invalidate(catalogReresolveCandidatesProvider);
      }
    });
  }
}

/// Empty-result sentinel used by `firstWhere`'s `orElse` — keeps the
/// search synchronous without throwing on an empty list.
class _SentinelCandidate extends CatalogReresolveCandidate {
  const _SentinelCandidate()
      : super(
          vehicleId: '',
          make: '',
          model: '',
          resolvedReferenceVehicleId: '',
          resolvedFuelType: '',
        );
}
