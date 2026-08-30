// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/settings_app_bar_action.dart';
import '../../../../core/widgets/settings_menu_tile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../feature_management/api.dart';
import 'settings/settings_topics.dart';

/// Settings root (#3884, Epic #3881) — a scannable list of topic tiles
/// with a search field on top.
///
/// Two-level information architecture: the root shows ONE tile per
/// topic (icon, title, one-line subtitle naming what is inside) and
/// nothing else — no collapsed foldables, no inline controls. Each tile
/// pushes a dedicated screen (`lib/app/routes/profile_routes.dart`) that
/// hosts the existing section widgets expanded under plain headers, so
/// every parameter is at most two taps away instead of four.
///
/// Topics, in order: Profiles & region · Vehicles & OBD2 · Driving &
/// consumption · Prices & alerts · Units & display · Features & use mode ·
/// Data sources & location · Sync & account (only with `Feature.tankSync`,
/// #1447 phase 3) · Privacy & data · Backup & restore · Advanced &
/// developer (only with the PAT / debug flag) · About.
///
/// The search field filters the tiles by title, subtitle and a per-topic
/// keyword list as the user types (see [SettingsTopic.matches]).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Cascading-feature gates (#1447 phase 3): a topic whose only content
    // is effectively-disabled never renders a tile, so the user does not
    // open an empty screen. Re-enabling the flag restores the tile.
    final manifest = ref.watch(featureManifestProvider);
    final enabledFlags = ref.watch(enabledFeaturesProvider);
    final tankSyncOn = isEffectivelyEnabled(
      Feature.tankSync,
      manifest,
      enabledFlags,
    );
    final patOn = enabledFlags.contains(Feature.developerPatToken);
    final debugOn = enabledFlags.contains(Feature.debugMode);

    final topics = buildSettingsTopics(
      l,
      tankSyncOn: tankSyncOn,
      advancedOn: patOn || debugOn,
    );
    final query = _query.text;
    final visible = topics.where((t) => t.matches(query)).toList();

    return PageScaffold(
      title: l.settings,
      // #3061 — Settings is a shell branch (no back-stack) → explicit back arrow.
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
        onPressed: () => context.go(ref.read(settingsReturnLocationProvider)),
      ),
      // #530 — compact vertical spacing (8 dp top / 16 dp sides).
      bodyPadding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('settingsSearchField'),
            controller: _query,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l.settingsSearchHint,
              isDense: true,
              border: const OutlineInputBorder(),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      key: const Key('settingsSearchClear'),
                      icon: const Icon(Icons.clear),
                      tooltip:
                          MaterialLocalizations.of(context).clearButtonTooltip,
                      onPressed: () {
                        _query.clear();
                        setState(() {});
                      },
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                if (visible.isEmpty)
                  Padding(
                    key: const Key('settingsSearchEmpty'),
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      l.settingsSearchNoResults(query.trim()),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                for (final topic in visible) ...[
                  SettingsMenuTile(
                    key: Key('settingsTopic_${topic.id.name}'),
                    icon: topic.icon,
                    title: topic.title,
                    subtitle: topic.subtitle,
                    onTap: () => context.push(topic.route),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
