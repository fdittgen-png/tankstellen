import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/sync/ntfy_service.dart';
import '../../../core/sync/supabase_client.dart';

part 'ntfy_setup_provider.g.dart';

/// UI state for the ntfy.sh push notification setup card.
///
/// Holds toggle state, topic, and progress flags so the widget
/// can be a [ConsumerWidget] and rebuild selectively.
class NtfySetupState {
  final bool enabled;
  final bool isSendingTest;
  final bool isToggling;
  final bool initialLoadDone;
  final String? topic;

  const NtfySetupState({
    this.enabled = false,
    this.isSendingTest = false,
    this.isToggling = false,
    this.initialLoadDone = false,
    this.topic,
  });

  NtfySetupState copyWith({
    bool? enabled,
    bool? isSendingTest,
    bool? isToggling,
    bool? initialLoadDone,
    String? topic,
  }) {
    return NtfySetupState(
      enabled: enabled ?? this.enabled,
      isSendingTest: isSendingTest ?? this.isSendingTest,
      isToggling: isToggling ?? this.isToggling,
      initialLoadDone: initialLoadDone ?? this.initialLoadDone,
      topic: topic ?? this.topic,
    );
  }
}

@riverpod
class NtfySetupController extends _$NtfySetupController {
  final NtfyService _ntfyService = NtfyService();

  @override
  NtfySetupState build() => const NtfySetupState();

  /// Ensure a topic is derived for the given user.
  void ensureTopic(String userId) {
    if (state.topic != null) return;
    state = state.copyWith(topic: _ntfyService.generateTopic(userId));
  }

  /// Load the current push_tokens state from Supabase once.
  Future<void> loadInitialState(String userId) async {
    if (state.initialLoadDone) return;
    state = state.copyWith(initialLoadDone: true);

    try {
      final client = TankSyncClient.client;
      if (client == null) return;

      final rows = await client
          .from('push_tokens')
          .select('enabled')
          .eq('user_id', userId)
          .limit(1);

      if (rows.isNotEmpty) {
        state = state.copyWith(
          enabled: rows.first['enabled'] as bool? ?? false,
        );
      }
    } catch (e) {
      debugPrint('NtfySetupController: failed to load push_tokens state: $e');
    }
  }

  /// Persist the toggle state in the push_tokens table.
  /// Returns true on success, false on failure.
  Future<bool> setEnabled(bool value, String userId) async {
    state = state.copyWith(isToggling: true);
    try {
      final client = TankSyncClient.client;
      if (client == null) {
        state = state.copyWith(isToggling: false);
        return false;
      }

      if (value) {
        final topic = _ntfyService.generateTopic(userId);
        await client.from('push_tokens').upsert({
          'user_id': userId,
          'ntfy_topic': topic,
          'enabled': true,
        }, onConflict: 'user_id');
      } else {
        await client.from('push_tokens').update({
          'enabled': false,
        }).eq('user_id', userId);
      }

      state = state.copyWith(enabled: value, isToggling: false);
      return true;
    } catch (e) {
      debugPrint('NtfySetupController: failed to update push_tokens: $e');
      state = state.copyWith(isToggling: false);
      return false;
    }
  }

  /// Send a test notification to the current topic.
  /// Returns true on success.
  Future<bool> sendTestNotification() async {
    final topic = state.topic;
    if (topic == null) return false;
    state = state.copyWith(isSendingTest: true);
    final success = await _ntfyService.sendTestNotification(topic);
    state = state.copyWith(isSendingTest: false);
    return success;
  }
}
