import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/profile/providers/profile_provider.dart';
import '../navigation/root_navigator_key.dart';
import '../widgets/snackbar_helper.dart';
import '../../l10n/app_localizations.dart';
import 'country_config.dart';
import 'country_switch_event.dart';

/// Wraps child and listens for country switch events.
/// Shows dialogs or snackbars depending on the event type.
class CountrySwitchListener extends ConsumerStatefulWidget {
  final Widget child;

  const CountrySwitchListener({super.key, required this.child});

  @override
  ConsumerState<CountrySwitchListener> createState() =>
      _CountrySwitchListenerState();
}

class _CountrySwitchListenerState extends ConsumerState<CountrySwitchListener> {
  // Cooldown: don't re-trigger for the same country within 10 minutes
  String? _lastDismissedCountry;
  DateTime? _lastDismissedAt;
  static const _cooldown = Duration(minutes: 10);

  bool _isOnCooldown(String countryCode) {
    if (_lastDismissedCountry == countryCode && _lastDismissedAt != null) {
      return DateTime.now().difference(_lastDismissedAt!) < _cooldown;
    }
    return false;
  }

  void _markDismissed(String countryCode) {
    _lastDismissedCountry = countryCode;
    _lastDismissedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CountrySwitchEvent?>(countrySwitchEventProvider,
        (previous, next) {
      if (next == null) return;
      if (_isOnCooldown(next.detectedCountryCode)) return;

      switch (next.action) {
        case CountrySwitchAction.autoSwitch:
          _handleAutoSwitch(next);
        case CountrySwitchAction.suggest:
          _handleSuggest(next);
        case CountrySwitchAction.noProfile:
          _handleNoProfile(next);
      }
    });

    return widget.child;
  }

  void _handleAutoSwitch(CountrySwitchEvent event) {
    final profile = event.matchingProfile!;
    ref.read(activeProfileProvider.notifier).switchProfile(profile.id);

    final l = AppLocalizations.of(context);
    final countryName =
        Countries.byCode(event.detectedCountryCode)?.name ??
            event.detectedCountryCode;
    final message = l?.switchedToProfile(profile.name, countryName) ??
        'Switched to profile "${profile.name}" ($countryName)';

    SnackBarHelper.showSuccess(context, message);
    _markDismissed(event.detectedCountryCode);
  }

  Future<void> _handleSuggest(CountrySwitchEvent event) async {
    final profile = event.matchingProfile!;
    // #1971 — mark the cooldown up-front. `CountrySwitchListener` lives
    // above the navigator (MaterialApp `builder:`), so its own context
    // has no Navigator; show the dialog against the navigator's overlay
    // context instead. If that is unavailable, skip without crashing.
    _markDismissed(event.detectedCountryCode);
    // Capture the notifier before the await — the user can leave the
    // screen while the dialog is open, which would make a post-await
    // `ref` use throw a disposed-ref error.
    final profileNotifier = ref.read(activeProfileProvider.notifier);
    final dialogContext = rootNavigatorKey.currentState?.overlay?.context;
    if (dialogContext == null) return;

    final l = AppLocalizations.of(dialogContext);
    final countryConfig = Countries.byCode(event.detectedCountryCode);
    final countryName = countryConfig?.name ?? event.detectedCountryCode;
    final countryFlag = countryConfig?.flag ?? '';

    final confirmed = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Text(countryFlag, style: const TextStyle(fontSize: 48)),
        title: Text(l?.switchProfileTitle ?? 'Country changed'),
        content: Text(
          l?.switchProfilePrompt(countryName, profile.name) ??
              'You are now in $countryName. Switch to profile "${profile.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l?.dismiss ?? 'Dismiss'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l?.switchProfile ?? 'Switch'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await profileNotifier.switchProfile(profile.id);
    }
  }

  Future<void> _handleNoProfile(CountrySwitchEvent event) async {
    // #1971 — mark the cooldown first so a missing navigator context
    // can never let the event re-fire and spam the crash, then show the
    // dialog against the navigator's overlay context (this listener's
    // own context sits above the navigator and has none).
    _markDismissed(event.detectedCountryCode);
    final dialogContext = rootNavigatorKey.currentState?.overlay?.context;
    if (dialogContext == null) return;

    final l = AppLocalizations.of(dialogContext);
    final countryConfig = Countries.byCode(event.detectedCountryCode);
    final countryName = countryConfig?.name ?? event.detectedCountryCode;
    final countryFlag = countryConfig?.flag ?? '';

    await showDialog<void>(
      context: dialogContext,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Text(countryFlag, style: const TextStyle(fontSize: 48)),
        title: Text(l?.noProfileForCountryTitle ?? 'No profile for this country'),
        content: Text(
          l?.noProfileForCountry(countryName) ??
              'You are in $countryName, but no profile is configured for it. Create one in Settings.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l?.dialogOk ?? 'OK'),
          ),
        ],
      ),
    );
  }
}
