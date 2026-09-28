// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/unit_formatter.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/currency_backfill.dart';
import '../../domain/currency_choices.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import '../../providers/currency_backfill_provider.dart';

/// Open the bulk currency statement (#4406) and, once applied, confirm
/// it with an Undo — the statement is reversible from the first second.
Future<void> showCurrencyBackfillDialog(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final l = AppLocalizations.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await showDialog<(int, String)>(
    context: context,
    builder: (_) => const CurrencyBackfillDialog(),
  );
  if (result == null) return;
  final (count, currency) = result;
  messenger.showSnackBar(
    SnackBarHelper.undoSnackBar(
      l.currencyBackfillDone(count, currency),
      undoLabel: l.undo,
      onUndo: () =>
          unawaited(container.read(currencyBackfillProvider).undo()),
    ),
  );
}

/// "My fill-ups on or before *date* were all paid in *currency*" — the
/// explicit statement #4406 asks for.
///
/// The currency picker has NO preselection and Apply stays disabled until
/// the driver picks one: a default taken from the profile or the active
/// country would be the very inference #4364 removed, behind a nicer
/// button. The cut-off starts at the newest unlabelled fill so the
/// statement covers the whole gap unless the driver narrows it; the
/// preview says how many records change and how many stay unknown.
class CurrencyBackfillDialog extends ConsumerStatefulWidget {
  const CurrencyBackfillDialog({super.key});

  @override
  ConsumerState<CurrencyBackfillDialog> createState() =>
      _CurrencyBackfillDialogState();
}

class _CurrencyBackfillDialogState
    extends ConsumerState<CurrencyBackfillDialog> {
  String? _currency;
  DateTime? _onOrBefore;
  bool _busy = false;

  DateTime _defaultCutoff(List<FillUp> unknown) => unknown
      .map((f) => f.date)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  /// A cut-off between the oldest and the newest unlabelled fill — past
  /// the newest one a later date labels nothing more.
  Future<void> _pickDate(DateTime initial, DateTime first, DateTime last) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(first.year, first.month, first.day),
      lastDate: last,
    );
    if (picked != null && mounted) setState(() => _onOrBefore = picked);
  }

  Future<void> _apply(DateTime cutoff) async {
    final currency = _currency;
    if (currency == null) return;
    setState(() => _busy = true);
    final result = await ref
        .read(currencyBackfillProvider)
        .apply(currency: currency, onOrBefore: cutoff);
    if (!mounted) return;
    Navigator.of(context).pop((result.labelled.length, currency));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fills = ref.watch(fillUpListProvider);
    final unknown = [for (final f in fills) if (hasUnknownCurrency(f)) f];
    if (unknown.isEmpty) {
      return AlertDialog(
        title: Text(l.currencyBackfillTitle),
        content: Text(l.currencyBackfillRemaining(0)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.cancel),
          ),
        ],
      );
    }
    final earliest =
        unknown.map((f) => f.date).reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = _defaultCutoff(unknown);
    final cutoff = _onOrBefore ?? latest;
    final candidates =
        currencyBackfillCandidates(fills, onOrBefore: cutoff).length;
    final currency = _currency;
    final remaining = currency == null
        ? null
        : applyCurrencyBackfill(
            fills,
            currency: currency,
            onOrBefore: cutoff,
            statedAt: cutoff,
          ).remaining;
    final locale = Localizations.localeOf(context).toString();

    return AlertDialog(
      title: Text(l.currencyBackfillTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.currencyBackfillIntro),
            const SizedBox(height: 12),
            ListTile(
              key: const Key('currency_backfill_date'),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event),
              title: Text(l.currencyBackfillOnOrBefore(
                  UnitFormatter.formatMediumDate(cutoff, locale: locale))),
              onTap: () => _pickDate(cutoff, earliest, latest),
            ),
            DropdownButtonFormField<String>(
              key: const Key('currency_backfill_picker'),
              initialValue: _currency,
              decoration:
                  InputDecoration(labelText: l.currencyBackfillCurrencyLabel),
              items: [
                for (final code in selectableCurrencyCodes())
                  DropdownMenuItem(value: code, child: Text(code)),
              ],
              onChanged: (v) => setState(() => _currency = v),
            ),
            if (currency != null) ...[
              const SizedBox(height: 12),
              Text(
                l.currencyBackfillPreview(candidates, currency),
                key: const Key('currency_backfill_preview'),
              ),
              Text(
                l.currencyBackfillRemaining(remaining!),
                key: const Key('currency_backfill_remaining'),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l.cancel),
        ),
        FilledButton(
          key: const Key('currency_backfill_apply'),
          onPressed: (currency == null || candidates == 0 || _busy)
              ? null
              : () => _apply(cutoff),
          child: Text(l.currencyBackfillApply),
        ),
      ],
    );
  }
}
