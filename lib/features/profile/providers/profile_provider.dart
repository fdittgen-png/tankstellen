import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../search/providers/search_provider.dart';
import '../domain/entities/user_profile.dart';
import '../data/repositories/profile_repository.dart';

// Re-export the generated repository provider so presentation code can read
// it via the providers/ layer without reaching into data/. The repository
// class itself stays internal to the data layer.
export '../data/repositories/profile_repository.dart' show profileRepositoryProvider;

part 'profile_provider.g.dart';

@Riverpod(keepAlive: true)
class ActiveProfile extends _$ActiveProfile {
  @override
  UserProfile? build() {
    final repo = ref.watch(profileRepositoryProvider);
    return repo.getActiveProfile();
  }

  Future<void> switchProfile(String id) async {
    final repo = ref.read(profileRepositoryProvider);
    final previousCountryCode = state?.countryCode;
    await repo.setActiveProfile(id);
    final next = repo.getActiveProfile();
    state = next;
    // #753 — a country switch leaves the previous country's search
    // results in cache. If the user then taps a widget/deep-link with
    // a colliding numeric station id, `stationDetailProvider` would
    // serve the old-country match before falling through to the API.
    // Resetting search state here closes that window for every
    // switch path (auto-detect, suggest dialog, manual in Settings).
    if (previousCountryCode != null &&
        previousCountryCode != next?.countryCode) {
      ref.invalidate(searchStateProvider);
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(profile);
    if (state?.id == profile.id) {
      state = profile;
    }
  }

  void refresh() {
    final repo = ref.read(profileRepositoryProvider);
    state = repo.getActiveProfile();
  }
}

@riverpod
List<UserProfile> allProfiles(Ref ref) {
  ref.watch(activeProfileProvider);
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getAllProfiles();
}
