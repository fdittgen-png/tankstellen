// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/add_fill_up_validators.dart';
import '../../domain/reconciliation_resolution.dart';

/// Raises the guided reconciliation workflow (Epic #2439 / #2442) and
/// resolves to the user's [ReconciliationResolution].
///
/// Three steps:
///   1. Explain — pumped vs recorded-trips, the gap, likely causes +
///      the consequence of leaving it unresolved.
///   2. Attribute — two yes/no questions; the answers route to Path A
///      (a fill-up is missing/wrong) or Path B (fill-ups right, a drive
///      went unrecorded — INCLUDING the "both individually correct →
///      gap is unrecorded driving" elimination case).
///   3. Gather — the minimal editable figure for the chosen path
///      (correction litres for A, missing distance for B).
///
/// All numeric arguments are PRE-FORMATTED by the caller in the active
/// locale (decimal separator + precision). [gapLiters] /
/// [defaultDistanceKm] are the raw values used to seed the editable
/// fields and to build the resolution.
///
/// A dismiss (scrim / back) resolves to
/// [ReconciliationResolution.deferred] — nothing is created and the
/// gap is kept (#2445 owns the full re-entry surface).
Future<ReconciliationResolution> showGuidedReconciliationWorkflow({
  required BuildContext context,
  required String pumpedText,
  required String consumedText,
  required String gapText,
  required double gapLiters,
  required double defaultDistanceKm,
}) async {
  final result = await showDialog<ReconciliationResolution>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _GuidedReconciliationDialog(
      pumpedText: pumpedText,
      consumedText: consumedText,
      gapText: gapText,
      gapLiters: gapLiters,
      defaultDistanceKm: defaultDistanceKm,
    ),
  );
  return result ?? const ReconciliationResolution.deferred();
}

enum _Step { explain, attribute, gather }

class _GuidedReconciliationDialog extends StatefulWidget {
  final String pumpedText;
  final String consumedText;
  final String gapText;
  final double gapLiters;
  final double defaultDistanceKm;

  const _GuidedReconciliationDialog({
    required this.pumpedText,
    required this.consumedText,
    required this.gapText,
    required this.gapLiters,
    required this.defaultDistanceKm,
  });

  @override
  State<_GuidedReconciliationDialog> createState() =>
      _GuidedReconciliationDialogState();
}

class _GuidedReconciliationDialogState
    extends State<_GuidedReconciliationDialog> {
  _Step _step = _Step.explain;

  /// Attribution answers. `true` = yes, `false` = no, `null` = not yet
  /// answered.
  bool? _fillUpsComplete;
  bool? _drivesRecorded;

  late final TextEditingController _litersCtrl;
  late final TextEditingController _distanceCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _litersCtrl = TextEditingController(text: _fmt(widget.gapLiters));
    _distanceCtrl = TextEditingController(text: _fmt(widget.defaultDistanceKm));
  }

  @override
  void dispose() {
    _litersCtrl.dispose();
    _distanceCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// Maintainer decision logic: a fill-up missing/wrong → Path A;
  /// otherwise (fill-ups correct, including the "both individually
  /// correct" elimination case) → Path B.
  ReconciliationPath get _resolvedPath => _fillUpsComplete == false
      ? ReconciliationPath.correctFillUp
      : ReconciliationPath.virtualTrajet;

  bool get _attributed => _fillUpsComplete != null && _drivesRecorded != null;

  void _defer() =>
      Navigator.of(context).pop(const ReconciliationResolution.deferred());

  void _apply() {
    final form = _formKey.currentState;
    if (form != null && !form.validate()) return;
    if (_resolvedPath == ReconciliationPath.correctFillUp) {
      Navigator.of(context).pop(
        ReconciliationResolution.correctFillUp(
          AddFillUpValidators.parseDouble(_litersCtrl.text),
        ),
      );
    } else {
      Navigator.of(context).pop(
        ReconciliationResolution.virtualTrajet(
          distanceKm: AddFillUpValidators.parseDouble(_distanceCtrl.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.reconcileWorkflowTitle),
      content: SingleChildScrollView(
        child: switch (_step) {
          _Step.explain => _buildExplain(l),
          _Step.attribute => _buildAttribute(l),
          _Step.gather => _buildGather(l),
        },
      ),
      actions: _buildActions(l),
    );
  }

  Widget _buildExplain(AppLocalizations l) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('reconcile-step-explain'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.reconcileWorkflowExplainHeadline(widget.gapText),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l.reconcileWorkflowExplainBody(
            widget.pumpedText,
            widget.consumedText,
            widget.gapText,
          ),
        ),
        const SizedBox(height: 12),
        Text(l.reconcileWorkflowExplainCauses),
        const SizedBox(height: 12),
        Text(
          l.reconcileWorkflowExplainConsequence,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildAttribute(AppLocalizations l) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('reconcile-step-attribute'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l.reconcileWorkflowAttributeQuestion,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        _YesNoQuestion(
          question: l.reconcileWorkflowFillUpsCompleteQuestion,
          value: _fillUpsComplete,
          yesLabel: l.reconcileWorkflowAnswerYes,
          noLabel: l.reconcileWorkflowAnswerNo,
          onChanged: (v) => setState(() => _fillUpsComplete = v),
        ),
        const SizedBox(height: 16),
        _YesNoQuestion(
          question: l.reconcileWorkflowDrivesRecordedQuestion,
          value: _drivesRecorded,
          yesLabel: l.reconcileWorkflowAnswerYes,
          noLabel: l.reconcileWorkflowAnswerNo,
          onChanged: (v) => setState(() => _drivesRecorded = v),
        ),
      ],
    );
  }

  Widget _buildGather(AppLocalizations l) {
    final pathA = _resolvedPath == ReconciliationPath.correctFillUp;
    return Form(
      key: _formKey,
      child: Column(
        key: const Key('reconcile-step-gather'),
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pathA
                ? (l.reconcileWorkflowPathAHint)
                : (l.reconcileWorkflowPathBHint),
          ),
          const SizedBox(height: 16),
          if (pathA)
            TextFormField(
              key: const Key('reconcile-correction-liters'),
              controller: _litersCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.reconcileWorkflowCorrectionLitersLabel,
                prefixIcon: const Icon(Icons.local_drink),
              ),
              validator: (v) => AddFillUpValidators.positiveNumber(v, l),
            )
          else
            TextFormField(
              key: const Key('reconcile-virtual-distance'),
              controller: _distanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.reconcileWorkflowVirtualDistanceLabel,
                prefixIcon: const Icon(Icons.straighten),
              ),
              validator: (v) => AddFillUpValidators.positiveNumber(v, l),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildActions(AppLocalizations l) {
    final deferBtn = TextButton(
      key: const Key('reconcile-decide-later'),
      onPressed: _defer,
      child: Text(l.reconcileWorkflowDecideLater),
    );
    switch (_step) {
      case _Step.explain:
        return [
          deferBtn,
          FilledButton(
            key: const Key('reconcile-next'),
            onPressed: () => setState(() => _step = _Step.attribute),
            child: Text(l.reconcileWorkflowNext),
          ),
        ];
      case _Step.attribute:
        return [
          TextButton(
            onPressed: () => setState(() => _step = _Step.explain),
            child: Text(l.reconcileWorkflowBack),
          ),
          deferBtn,
          FilledButton(
            key: const Key('reconcile-next'),
            onPressed: _attributed
                ? () => setState(() => _step = _Step.gather)
                : null,
            child: Text(l.reconcileWorkflowNext),
          ),
        ];
      case _Step.gather:
        return [
          TextButton(
            onPressed: () => setState(() => _step = _Step.attribute),
            child: Text(l.reconcileWorkflowBack),
          ),
          deferBtn,
          FilledButton(
            key: const Key('reconcile-apply'),
            onPressed: _apply,
            child: Text(l.reconcileWorkflowApply),
          ),
        ];
    }
  }
}

/// A labelled yes/no segmented control for the attribution step.
class _YesNoQuestion extends StatelessWidget {
  final String question;
  final bool? value;
  final String yesLabel;
  final String noLabel;
  final ValueChanged<bool> onChanged;

  const _YesNoQuestion({
    required this.question,
    required this.value,
    required this.yesLabel,
    required this.noLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(question, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(yesLabel)),
            ButtonSegment(value: false, label: Text(noLabel)),
          ],
          selected: value == null ? <bool>{} : {value!},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) {
            if (s.isNotEmpty) onChanged(s.first);
          },
        ),
      ],
    );
  }
}
