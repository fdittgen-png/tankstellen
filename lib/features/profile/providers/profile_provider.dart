import 'package:riverpod_annotation/riverpod_annotation.dart';
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
    await repo.setActiveProfile(id);
    state = repo.getActiveProfile();
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
