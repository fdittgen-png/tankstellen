// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../l10n/app_localizations.dart';
import 'criteria/criteria_chip_group.dart';

/// The search radius (km): preset chips first, a custom slider second.
///
/// #3927 — the four radii people actually use are one tap away as chips.
/// Presets outside `[minKm, maxKm]` are not offered: `SearchRadius.set`
/// clamps to 25 km, so a 50 km chip would silently land on 25 and lie
/// about what it did.
///
/// #4199 (Epic #4198) — the value used to show three times at once: in the
/// title row, in the slider's drag bubble and on the selected chip. Now a
/// preset value is shown by its chip alone; the slider appears only behind
/// the Custom chip (or when the radius is not a preset), and then the
/// title row carries the value because no chip does.
class SearchRadiusSlider extends StatefulWidget {
  final double radiusKm;
  final ValueChanged<double> onChanged;
  final double minKm;
  final double maxKm;

  /// The radii offered as one-tap chips, filtered to the slider's range.
  static const List<int> presetsKm = [5, 10, 25, 50];

  const SearchRadiusSlider({
    super.key,
    required this.radiusKm,
    required this.onChanged,
    this.minKm = 1,
    this.maxKm = 25,
  });

  @override
  State<SearchRadiusSlider> createState() => _SearchRadiusSliderState();
}

class _SearchRadiusSliderState extends State<SearchRadiusSlider> {
  /// The user opened the custom control, or dragged it. Kept while the
  /// drag passes over a preset value so the slider never vanishes under
  /// the finger.
  bool _customRequested = false;

  void _selectPreset(int km) {
    setState(() => _customRequested = false);
    widget.onChanged(km.toDouble());
  }

  void _drag(double km) {
    if (!_customRequested) setState(() => _customRequested = true);
    widget.onChanged(km);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final value = widget.radiusKm.clamp(widget.minKm, widget.maxKm).toDouble();
    final rounded = value.round();
    final presets = SearchRadiusSlider.presetsKm
        .where((km) => km >= widget.minKm && km <= widget.maxKm)
        .toList(growable: false);
    final custom = _customRequested || !presets.contains(rounded);
    final customControl = custom
      // #1962 — the compact reaction overlay keeps the row short.
      ? SliderTheme(
          data: SliderTheme.of(context).copyWith(
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
          ),
          child: Slider(
            value: value,
            min: widget.minKm,
            max: widget.maxKm,
            divisions: (widget.maxKm - widget.minKm).round(),
            // No drag bubble — the title row already shows it —
            // but screen readers still hear the value in km.
            semanticFormatterCallback: (v) =>
                l10n.searchSummaryRadiusValue('${v.round()}'),
            onChanged: _drag,
          ),
        )
      : const SizedBox(width: double.infinity);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // #3949 — the section name is the grammar's title role, like the
        // fuel / amenity / brand headers above and below it.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                l10n.searchRadius,
                style: AppText.title(context),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (custom) ...[
              const SizedBox(width: Spacing.md),
              Text(
                l10n.searchSummaryRadiusValue('$rounded'),
                style: AppText.title(context).copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: Spacing.sm),
        Wrap(
          spacing: Spacing.md,
          runSpacing: Spacing.sm,
          children: [
            for (final km in presets)
              ChoiceChip(
                key: ValueKey('criteria-radius-preset-$km'),
                label: Text(l10n.searchSummaryRadiusValue('$km')),
                selected: !custom && rounded == km,
                // #3949 — the tightened criteria-chip geometry shared with
                // the fuel group, so both read as one chip role.
                padding: kCriteriaChipPadding,
                labelPadding: kCriteriaChipLabelPadding,
                visualDensity: VisualDensity.compact,
                onSelected: (_) => _selectPreset(km),
              ),
            ChoiceChip(
              key: const ValueKey('criteria-radius-custom'),
              label: Text(l10n.criteriaRadiusCustom),
              selected: custom,
              padding: kCriteriaChipPadding,
              labelPadding: kCriteriaChipLabelPadding,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() => _customRequested = true),
            ),
          ],
        ),
        // #4238 — reduced motion: the control appears without a size
        // animation (a zero-duration AnimatedSize mutates layout mid-pass).
        if (MediaQuery.disableAnimationsOf(context))
          customControl
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: customControl,
          ),
      ],
    );
  }
}
