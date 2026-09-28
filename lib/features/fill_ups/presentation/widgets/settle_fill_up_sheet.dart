// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: AGPL-3.0-or-later

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../../../core/utils/unit_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/currency_choices.dart';
import '../../domain/entities/fill_up.dart';
import '../../providers/consumption_providers.dart';
import 'fill_up_numeric_field.dart';

/// How the driver states the converted money (#4437).
enum SettleMode {
  /// The amount printed on the card statement — `card settlement`.
  amount,

  /// A rate typed in by hand — `entered by hand`, and shown as such.
  rate,
}

/// The one edit surface for a SAVED fill-up's money (#4437 C).
///
/// Opened from a fill-up card whose record is in a foreign currency or in
/// none at all. It lets the driver:
///
///  * state the currency a legacy (unstamped) record was paid in — a
///    picker with NO preselection, because a default taken from the
///    profile or today's country is exactly the inference #4364 removed;
///  * attach what their card statement charged, in their profile
///    currency — stored verbatim and shown verbatim, the implied rate
///    labelled `card settlement` and dated to the transaction;
///  * or type a rate by hand, which stays labelled `entered by hand`.
///
/// Litres, odometer and the native amount are never touched here, so
/// consumption is identical before and after (#4428).
class SettleFillUpSheet extends ConsumerStatefulWidget {
  final FillUp fillUp;

  const SettleFillUpSheet({super.key, required this.fillUp});

  @override
  ConsumerState<SettleFillUpSheet> createState() => _SettleFillUpSheetState();
}

class _SettleFillUpSheetState extends ConsumerState<SettleFillUpSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _rateCtrl;
  late SettleMode _mode;
  String? _currency;

  /// The currency the settled amount is in: the profile's, named on the
  /// field label so the statement is explicit (#4437 B).
  String get _profileCurrency => PriceFormatter.currencyCode;

  @override
  void initState() {
    super.initState();
    final f = widget.fillUp;
    final recorded = f.currency?.trim().toUpperCase();
    _currency = (recorded == null || recorded.isEmpty) ? null : recorded;
    _mode = f.isRateEnteredByHand ? SettleMode.rate : SettleMode.amount;
    final settled = f.settledMoney;
    _amountCtrl = TextEditingController(
      text: settled != null && !f.isRateEnteredByHand
          ? _prefill(settled.amount, 2)
          : '',
    );
    _rateCtrl = TextEditingController(
      text: settled != null && f.isRateEnteredByHand && f.totalCost > 0
          ? _prefill(settled.amount / f.totalCost, 4)
          : '',
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  // i18n-ignore-format: TextEditingController prefill — re-parsed as a dot-decimal number, not display text
  String _prefill(double v, int digits) => v.toStringAsFixed(digits);

  /// Whether a conversion is meaningful: a named record currency that is
  /// not already the profile's.
  bool get _canSettle => _currency != null && _currency != _profileCurrency;

  String? _validatePositive(String? v, AppLocalizations l) {
    if (v == null || v.trim().isEmpty) return null; // optional
    final parsed = double.tryParse(v.replaceAll(',', '.'));
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return l.fieldInvalidNumber;
    }
    return null;
  }

  FillUp _updated() {
    var f = widget.fillUp;
    final code = _currency;
    if (code != null && f.currency?.trim().toUpperCase() != code) {
      f = f.copyWith(currency: code);
    }
    if (!_canSettle) return f.withoutSettlement();
    final raw = (_mode == SettleMode.amount ? _amountCtrl : _rateCtrl).text;
    if (raw.trim().isEmpty) return f.withoutSettlement();
    final value = AddFillUpValidators.parseDouble(raw);
    return _mode == SettleMode.amount
        ? f.settledByCard(amount: value, currency: _profileCurrency)
        : f.settledByHandRate(rate: value, currency: _profileCurrency);
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    await ref.read(fillUpListProvider.notifier).update(_updated());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _removeSettlement() async {
    await ref
        .read(fillUpListProvider.notifier)
        .update(widget.fillUp.withoutSettlement());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final f = widget.fillUp;
    final recordedKnown = f.currency != null && f.currency!.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.currency_exchange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l.settleFillUpTitle,
                      style: AppText.title(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // The record as it stands — litres and the native amount
              // are shown, never edited here.
              Wrap(
                spacing: 16,
                children: [
                  Text(UnitFormatter.formatVolume(f.liters),
                      style: AppText.title(context)),
                  Text(
                    PriceFormatter.formatTotalIn(f.totalCost, _currency),
                    key: const Key('settle_native_amount'),
                    style: AppText.title(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!recordedKnown) ...[
                Text(
                  l.settleFillUpCurrencyUnknownIntro,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: const Key('settle_currency_picker'),
                  initialValue: _currency,
                  decoration: InputDecoration(
                    labelText: l.settleFillUpCurrencyLabel,
                  ),
                  items: [
                    for (final code in selectableCurrencyCodes())
                      DropdownMenuItem(value: code, child: Text(code)),
                  ],
                  validator: (v) => v == null ? l.fieldRequired : null,
                  onChanged: (v) => setState(() => _currency = v),
                ),
                const SizedBox(height: 12),
              ],
              if (_canSettle) ...[
                Text(
                  l.settleFillUpIntro(_currency!, _profileCurrency),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<SettleMode>(
                  key: const Key('settle_mode'),
                  segments: [
                    ButtonSegment(
                      value: SettleMode.amount,
                      icon: const Icon(Icons.credit_card),
                      label: Text(l.settleFillUpModeAmount),
                    ),
                    ButtonSegment(
                      value: SettleMode.rate,
                      icon: const Icon(Icons.edit_note),
                      label: Text(l.settleFillUpModeRate),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
                const SizedBox(height: 12),
                if (_mode == SettleMode.amount)
                  FillUpNumericField(
                    key: const Key('settle_amount_field'),
                    controller: _amountCtrl,
                    label: l.settleFillUpAmountLabel(_profileCurrency),
                    icon: Icons.credit_card,
                    helperText: l.settleFillUpAmountHint,
                    validator: (v) => _validatePositive(v, l),
                  )
                else
                  FillUpNumericField(
                    key: const Key('settle_rate_field'),
                    controller: _rateCtrl,
                    label: l.settleFillUpRateLabel(
                        _currency!, _profileCurrency),
                    icon: Icons.edit_note,
                    helperText: l.settleFillUpRateHint,
                    validator: (v) => _validatePositive(v, l),
                  ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  if (f.isSettled)
                    TextButton(
                      key: const Key('settle_remove'),
                      onPressed: _removeSettlement,
                      child: Text(l.settleFillUpRemove),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const Key('settle_save'),
                    onPressed: _save,
                    child: Text(l.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
