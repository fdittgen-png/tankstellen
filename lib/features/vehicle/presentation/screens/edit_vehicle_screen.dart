// Copyright (c) 2026 Florian DITTGEN
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/brand_logo_mapper.dart';
import '../../../../core/widgets/discard_changes_dialog.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/obd2_vin_reader.dart';
import '../../data/reference_vehicle_catalog_provider.dart';
import '../../data/vehicle_profile_catalog_matcher.dart';
import '../../domain/entities/reference_vehicle.dart';
import '../../../../core/domain/vehicle_profile.dart';
import '../../domain/entities/vin_data.dart';
import '../../providers/obd2_vin_reader_provider.dart';
import '../../providers/vehicle_providers.dart';
import '../../providers/vin_adapter_pair_auto_populator_provider.dart';
import '../../providers/vin_decoder_provider.dart';
import '../widgets/catalog_reset_confirm_dialog.dart';
import '../widgets/reference_vehicle_picker.dart';
import '../widgets/ve_reset_confirm_dialog.dart';
import '../widgets/vehicle_edit_form.dart';
import '../widgets/vehicle_form_controllers.dart';
import '../widgets/vehicle_save_actions.dart';
import '../widgets/vin_confirm_dialog.dart';
import '../widgets/vin_info_sheet.dart';
import '../../../../core/logging/error_logger.dart';
import 'topics/vehicle_adapter_topic_screen.dart';
import 'topics/vehicle_auto_record_topic_screen.dart';
import 'topics/vehicle_calibration_topic_screen.dart';
import 'topics/vehicle_edit_topic.dart';
import 'topics/vehicle_service_reminders_topic_screen.dart';

part 'edit_vehicle_screen_actions.dart';
part 'edit_vehicle_screen_catalog_reset.dart';
part 'edit_vehicle_screen_topics.dart';

/// Sentinel for the four "leave alone" arguments on
/// [_VehicleEditActions._saveCalibrationOverride] — `null` is a
/// valid override value (clears the manual override) so a separate
/// marker is needed to distinguish "don't touch" from "set to null".
const Object _kSentinel = Object();

/// Form for adding or editing a [VehicleProfile].
///
/// Pass [vehicleId] to edit an existing profile; omit to create a new one.
class EditVehicleScreen extends ConsumerStatefulWidget {
  final String? vehicleId;

  const EditVehicleScreen({super.key, this.vehicleId});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen>
    with _VehicleEditActions, _VehicleCatalogResetAction, _VehicleEditTopics {
  @override
  final _formKey = GlobalKey<FormState>();
  @override
  final _ctrl = VehicleFormControllers();

  // Scroll controller for the host `ListView` — owned here so the form
  // stays a pure view of the State.
  final ScrollController _scrollController = ScrollController();

  // #3234 — the mutable form state (_type / _connectors / _adapterMac / the
  // VIN-decode + engine scalars / the busy flags / the picked catalog row) and
  // the imperative actions that read+write it now live in the `_VehicleEditActions`
  // part mixin; `build` + the load path below reference them as inherited
  // members, unchanged. #3900 — the topic sub-screens (adapter, calibration,
  // reminders, auto-record) are opened by the `_VehicleEditTopics` part mixin.

  @override
  void initState() {
    super.initState();
    // Rebuild on every name keystroke so the header title tracks input.
    _ctrl.nameController.addListener(_refresh);
    if (widget.vehicleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExisting());
    } else {
      // #1693 — new-vehicle path has no async load; the construction
      // defaults are the discard-guard baseline.
      _ctrl.snapshotBaseline();
    }
  }

  void _refresh() => mounted ? setState(() {}) : null;

  void _loadExisting() {
    final list = ref.read(vehicleProfileListProvider);
    _applyLoadedList(list);
  }

  /// Copy the matching [VehicleProfile] from [list] into the form's
  /// controllers and scalar state. Returns true when a profile matched
  /// and was applied, false when none was found (the provider hasn't
  /// resolved yet, the id was deleted, etc.).
  ///
  /// Used by both the initial postFrameCallback path and the
  /// `ref.listen` second-chance refill (#1328). The
  /// [_hasInitiallyLoaded] flag is set on success so subsequent
  /// rebuilds don't clobber user edits.
  bool _applyLoadedList(List<VehicleProfile> list) {
    final existing = list.where((v) => v.id == widget.vehicleId).firstOrNull;
    if (existing == null) return false;
    final snap = _ctrl.load(existing);
    // #1693 — the freshly-loaded profile is the discard-guard baseline.
    _ctrl.snapshotBaseline();
    setState(() {
      _existingId = snap.id;
      _type = snap.type;
      _connectors
        ..clear()
        ..addAll(snap.connectors);
      _adapterMac = snap.adapterMac;
      _adapterName = snap.adapterName;
      _engineDisplacementCc = snap.engineDisplacementCc;
      _engineCylinders = snap.engineCylinders;
      _curbWeightKg = snap.curbWeightKg;
      _multiFuelCapable = snap.multiFuelCapable;
      _hasInitiallyLoaded = true;
    });
    return true;
  }

  @override
  void dispose() {
    _ctrl.nameController.removeListener(_refresh);
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Brand-accent colour from the vehicle name. Falls back to the
  /// theme primary when no brand matches. The brand mapper is shared
  /// with fuel stations — overlap is rare but harmless.
  Color _brandAccent(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final name = _ctrl.nameController.text;
    if (name.isEmpty) return primary;
    for (final token in name.toLowerCase().split(RegExp(r'\s+'))) {
      if (BrandLogoMapper.hasLogo(token)) return primary;
    }
    return primary;
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existingId != null || widget.vehicleId != null;
    final accent = _brandAccent(context);

    // #1328 — second-chance refill for the pre-population race. When the
    // initial postFrameCallback ran before the provider resolved (Hive
    // box still hydrating, etc.), the form controllers stayed blank.
    // Listening here re-runs the load the moment the provider produces
    // a list that contains our target id. Guarded by
    // `_hasInitiallyLoaded` so user edits aren't clobbered by later
    // provider updates (e.g. `_save()` writing the persisted profile
    // back into the list).
    final targetId = widget.vehicleId;
    if (targetId != null) {
      ref.listen<List<VehicleProfile>>(vehicleProfileListProvider,
          (prev, next) {
        if (_hasInitiallyLoaded) return;
        if (next.any((v) => v.id == targetId)) {
          _applyLoadedList(next);
        }
      });
    }

    // #1693 — guard unsaved vehicle edits. `canPop` blocks the system
    // back gesture and the AppBar back button (both route through
    // `Navigator.maybePop`); the imperative `pop()` in the save path
    // is unaffected. The form body itself is the presentational
    // [VehicleEditForm] (#3234) — the State feeds it the live form values +
    // pre-built `setState`/action callbacks.
    return PopScope(
      canPop: !_ctrl.isDirty,
      onPopInvokedWithResult: _onPopInvoked,
      child: VehicleEditForm(
        formKey: _formKey,
        scrollController: _scrollController,
        isEdit: isEdit,
        accent: accent,
        ctrl: _ctrl,
        type: _type,
        onTypeChanged: (t) => setState(() => _type = t),
        decodingVin: _decodingVin,
        onDecodeVin: _decodeVin,
        onShowVinInfo: _showVinInfo,
        adapterMac: _adapterMac,
        onReadVinFromCar: (_adapterMac != null && _adapterMac!.isNotEmpty)
            ? _readVinFromCar
            : null,
        readingVinFromCar: _readingVinFromCar,
        connectors: _connectors,
        onToggleConnector: (c) => setState(() {
          if (_connectors.contains(c)) {
            _connectors.remove(c);
          } else {
            _connectors.add(c);
          }
        }),
        multiFuelCapable: _multiFuelCapable,
        onMultiFuelCapableChanged: (v) =>
            setState(() => _multiFuelCapable = v),
        onFuelTypeChanged: (_) => setState(() {}),
        numberValidator: _validateOptionalNumber,
        existingId: _existingId,
        adapterName: _adapterName,
        onOpenTopic: _openTopic,
        onOpenCatalogPicker: _openCatalogPicker,
        onSave: _save,
      ),
    );
  }

  /// #1693 — discard guard for a blocked pop (system back / AppBar
  /// back button). Confirms before discarding unsaved vehicle edits.
  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    if (didPop) return;
    final discard = await showDiscardChangesDialog(context);
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }
}
