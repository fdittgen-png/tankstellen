import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'profile_provider.dart';

part 'gamification_enabled_provider.g.dart';

/// Master gate for gamification surfaces (#1194).
///
/// Reads the [UserProfile.gamificationEnabled] flag from the active
/// profile. Returns `true` when no profile is loaded yet so the very
/// first frame on a cold launch keeps the existing behaviour — the
/// underlying flag itself defaults to `true` for both freshly-created
/// and migrated profiles, so this fall-back only applies before the
/// active profile is resolved.
///
/// Consumers wrap their gamification UI with:
/// ```dart
/// if (!ref.watch(gamificationEnabledProvider)) {
///   return const SizedBox.shrink();
/// }
/// ```
///
/// The achievement-engine itself is intentionally NOT gated — it keeps
/// running so that toggling back on instantly restores any badges
/// earned during the opt-out window.
@riverpod
bool gamificationEnabled(Ref ref) {
  final profile = ref.watch(activeProfileProvider);
  return profile?.gamificationEnabled ?? true;
}
