// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Modal bottom sheet that explains what a VIN is, why the app asks
/// for it, the privacy guarantees, and where to find it on the car
/// (#895).
///
/// Designed around the product principle "the app must be
/// self-explaining": the VIN field label alone does not convey
/// enough context, so an `Icons.info_outline` tap-target next to the
/// label opens this sheet with four labeled sections.
class VinInfoSheet extends StatelessWidget {
  const VinInfoSheet({super.key});

  /// Launch the info sheet. Returns once the user dismisses it.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const VinInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // Cap the sheet height so the long body scrolls instead of
    // spilling past the top of the screen on compact phones.
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.vinInfoTooltip,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _Section(
                title: l.vinInfoSectionWhatTitle,
                body: l.vinInfoSectionWhatBody,
              ),
              _Section(
                title: l.vinInfoSectionWhyTitle,
                body: l.vinInfoSectionWhyBody,
              ),
              _Section(
                title: l.vinInfoSectionPrivacyTitle,
                body: l.vinInfoSectionPrivacyBody,
              ),
              _Section(
                title: l.vinInfoSectionWhereTitle,
                body: l.vinInfoSectionWhereBody,
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.vinInfoDismiss),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One labeled section inside the VIN info sheet.
class _Section extends StatelessWidget {
  final String title;
  final String body;

  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
