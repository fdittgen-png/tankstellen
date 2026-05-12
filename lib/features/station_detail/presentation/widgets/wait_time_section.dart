import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/country/country_provider.dart';
import '../../../../core/providers/app_state_provider.dart';
import '../../../../core/sync/wait_time_active_session.dart';
import '../../../../core/sync/wait_time_sync.dart';
import '../../../../core/widgets/section_card.dart';
import '../../../../l10n/app_localizations.dart';

/// "Track my wait" section on the station-detail screen (#1119
/// phase 2). Renders three things stacked in one card:
///
///  1. Aggregate hint — when the server has at least 5 paired pings
///     for the station's most recent hour bucket, show "~N min wait".
///     Hidden entirely on null (sparse data, unauthenticated, or
///     network failure).
///  2. Track-my-wait toggle — fires `recordArrival` on tap, persists
///     the active session to Hive, and flips to an "elapsed time +
///     I'm leaving" state. Tap again → `recordDeparture`, clear, back
///     to OFF.
///  3. Auto-cleanup of stale sessions — anything older than 1h on
///     screen mount is best-effort closed; the server-side
///     `MAX_WAIT_SECONDS` is the authoritative dedupe.
///
/// The whole section is hidden when consent is OFF — the consent
/// settings page owns the opt-in UX, surfacing it twice would just
/// be noise.
class WaitTimeSection extends ConsumerStatefulWidget {
  final String stationId;

  const WaitTimeSection({super.key, required this.stationId});

  @override
  ConsumerState<WaitTimeSection> createState() => _WaitTimeSectionState();
}

class _WaitTimeSectionState extends ConsumerState<WaitTimeSection> {
  WaitTimeHint? _hint;

  @override
  void initState() {
    super.initState();
    // Best-effort cleanup of any stale (>1h) session left over from a
    // previous launch + first-frame fetch of the aggregate hint. The
    // elapsed-time label refreshes naturally when the user re-opens
    // the screen; we deliberately do NOT spin a long-running
    // `Timer.periodic` here — it leaks pending timers into widget
    // tests AND doesn't move the needle (a one-minute granularity is
    // good enough for a "you arrived ~3 min ago" label).
    //
    // We gate the post-frame callback on consent — when consent is
    // OFF the widget short-circuits to `SizedBox.shrink()` and the
    // Hive box reads / network calls aren't just wasted, they CRASH
    // any host test that doesn't bother to wire up Hive (none of the
    // other station-detail tests do, because phase 1 didn't need it).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final consent = ref.read(gdprConsentProvider).communityWaitTime;
      if (!consent) return;
      _expireStaleSession();
      _loadHint();
    });
  }

  void _expireStaleSession() {
    final store = ref.read(waitTimeActiveSessionStoreProvider);
    // read() already drops a stale entry as a side-effect — we don't
    // need to do anything with the result here. The server-side
    // MAX_WAIT_SECONDS handles the missing departure.
    store.read(now: DateTime.now());
  }

  Future<void> _loadHint() async {
    final hint =
        await WaitTimeSync.fetchAggregateForStation(stationId: widget.stationId);
    if (!mounted) return;
    setState(() {
      _hint = hint;
    });
  }

  Future<void> _onTrackPressed(bool consentEnabled, String countryCode) async {
    final sessionId = await WaitTimeSync.recordArrival(
      stationId: widget.stationId,
      countryCode: countryCode,
      consentEnabled: consentEnabled,
    );
    if (sessionId == null) return; // unauth / consent off / failure — silent
    final store = ref.read(waitTimeActiveSessionStoreProvider);
    await store.start(WaitTimeActiveSession(
      sessionId: sessionId,
      stationId: widget.stationId,
      countryCode: countryCode,
      arrivedAt: DateTime.now(),
    ));
    ref.invalidate(waitTimeActiveSessionProvider);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onLeavingPressed(bool consentEnabled) async {
    final store = ref.read(waitTimeActiveSessionStoreProvider);
    final session = store.read();
    if (session == null) return;
    await WaitTimeSync.recordDeparture(
      sessionId: session.sessionId,
      stationId: session.stationId,
      countryCode: session.countryCode,
      consentEnabled: consentEnabled,
    );
    await store.clear();
    ref.invalidate(waitTimeActiveSessionProvider);
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final consent = ref.watch(gdprConsentProvider).communityWaitTime;
    if (!consent) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final session = ref.watch(waitTimeActiveSessionProvider);
    final country = ref.watch(activeCountryProvider).code;

    final children = <Widget>[];
    if (_hint != null) {
      final minutes = _hint!.medianMinutes;
      final label = l10n?.waitTimeHint(minutes) ?? '~$minutes min wait';
      children.add(Row(
        children: [
          Icon(Icons.access_time, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ));
      children.add(const SizedBox(height: 12));
    }

    if (session != null && session.stationId == widget.stationId) {
      final elapsedMin =
          DateTime.now().difference(session.arrivedAt).inMinutes;
      final elapsedLabel = l10n?.waitTimeElapsedShort(elapsedMin) ??
          '$elapsedMin min so far';
      children.add(Row(
        children: [
          Expanded(
            child: Text(elapsedLabel, style: theme.textTheme.bodyMedium),
          ),
          FilledButton.tonal(
            onPressed: () => _onLeavingPressed(consent),
            child: Text(l10n?.waitTimeTrackEnd ?? "I'm leaving"),
          ),
        ],
      ));
    } else {
      children.add(Align(
        alignment: AlignmentDirectional.centerStart,
        child: FilledButton.tonal(
          onPressed: () => _onTrackPressed(consent, country),
          child: Text(l10n?.waitTimeTrackStart ?? 'Track my wait'),
        ),
      ));
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
