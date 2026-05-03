import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_state_provider.dart';
import '../../../../l10n/app_localizations.dart';
import '../../providers/map_breadcrumb_provider.dart';

/// In-app overlay that renders the most recent `[map-...]` breadcrumbs
/// captured by [MapBreadcrumbsNotifier] (#1316 phase 2).
///
/// Always visible in `kDebugMode`; in release builds the user enables
/// it via the hidden 5-tap gesture on the Carte AppBar title (which
/// flips [mapDebugOverlayProvider]). The phase-1 instrumentation only
/// produced messages in `adb logcat`, which the user has not been able
/// to capture across the prior repros — this overlay closes the
/// diagnostic loop on-device.
///
/// The widget self-hides when neither path is enabled, returning a
/// zero-cost [SizedBox.shrink], so the screen pays nothing for it in
/// production builds where the flag is off.
class MapDebugBreadcrumbOverlay extends ConsumerWidget {
  const MapDebugBreadcrumbOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flag = ref.watch(mapDebugOverlayProvider);
    final visible = kDebugMode || flag;
    if (!visible) return const SizedBox.shrink();

    final crumbs = ref.watch(mapBreadcrumbsProvider);
    final l10n = AppLocalizations.of(context);

    return Positioned(
      right: 8,
      bottom: 8,
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 280,
            maxHeight: 320,
            minWidth: 200,
            minHeight: 100,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n?.mapDebugOverlayTitle ?? 'Map breadcrumbs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(mapBreadcrumbsProvider.notifier)
                              .clear();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.mapDebugOverlayClearButton ?? 'Clear',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .read(mapDebugOverlayProvider.notifier)
                              .disable();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(0, 32),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n?.mapDebugOverlayCloseButton ?? 'Close',
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      reverse: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final c in crumbs)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 1,
                              ),
                              child: Text(
                                '[${c.tag}] ${c.message}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  height: 1.2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
