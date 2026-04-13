import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../providers/sync_setup_provider.dart';
import '../widgets/auth_form_widget.dart';
import '../widgets/qr_scanner_screen.dart';
import '../widgets/sync_credentials_step.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/sync_done_step.dart';
import '../widgets/sync_mode_step.dart';

/// Clean 3-step sync setup: Mode -> Credentials (if needed) -> Auth -> Done.
///
/// ## Architecture
/// - UI only -- no business logic. Delegates all sync operations to [SyncState].
/// - Reusable widgets: [SyncModeCard], [AuthFormWidget] are app-agnostic.
/// - Database credentials abstracted via [SyncState.connectCommunity()] and
///   [SyncState.connect(url, key)].
/// - Wizard step + UI flags live in [syncSetupControllerProvider]; only the
///   two [TextEditingController]s remain local (Flutter lifecycle).
class SyncSetupScreen extends ConsumerStatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  ConsumerState<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

class _SyncSetupScreenState extends ConsumerState<SyncSetupScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  String _titleFor(SyncSetupStep step, SyncMode mode) {
    final l10n = AppLocalizations.of(context);
    return switch (step) {
      SyncSetupStep.mode => l10n?.syncWizardTitleConnect ?? 'Connect TankSync',
      SyncSetupStep.credentials => mode == SyncMode.private
          ? (l10n?.syncSetupTitleYourDatabase ?? 'Your database')
          : (l10n?.syncSetupTitleJoinGroup ?? 'Join a group'),
      SyncSetupStep.auth => l10n?.syncSetupTitleAccount ?? 'Your account',
      SyncSetupStep.done => l10n?.syncSuccessTitle ?? 'Successfully connected!',
    };
  }

  void _onBack() {
    final setup = ref.read(syncSetupControllerProvider);
    final ctrl = ref.read(syncSetupControllerProvider.notifier);
    switch (setup.step) {
      case SyncSetupStep.mode:
        Navigator.pop(context);
      case SyncSetupStep.credentials:
        ctrl.goToStep(SyncSetupStep.mode);
      case SyncSetupStep.auth:
        ctrl.goToStep(
          setup.selectedMode == SyncMode.community
              ? SyncSetupStep.mode
              : SyncSetupStep.credentials,
        );
      case SyncSetupStep.done:
        Navigator.pop(context);
    }
  }

  Future<void> _onAuthSubmit({
    required bool isEmail,
    String? email,
    String? password,
    required bool isSignUp,
  }) async {
    final ctrl = ref.read(syncSetupControllerProvider.notifier);
    final setup = ref.read(syncSetupControllerProvider);

    ctrl.startLoading();

    try {
      final syncNotifier = ref.read(syncStateProvider.notifier);

      if (setup.selectedMode == SyncMode.community) {
        await syncNotifier.connectCommunity();
      } else {
        final url = _urlController.text.trim();
        final key = _keyController.text.trim();
        await syncNotifier.connect(url, key, mode: setup.selectedMode);
      }

      if (isEmail && email != null && password != null) {
        await syncNotifier.signInWithEmail(email, password, isSignUp: isSignUp);
      }

      if (!mounted) return;
      ctrl.goToStep(SyncSetupStep.done);
      ctrl.stopLoading();

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ctrl.setError(e.toString());
    }
  }

  Future<void> _scanQr() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      try {
        final json = jsonDecode(result) as Map<String, dynamic>;
        _urlController.text = json['url']?.toString() ?? '';
        _keyController.text = json['key']?.toString() ?? '';
      } catch (e) {
        debugPrint('QR code parse failed: $e');
        if (mounted) {
          SnackBarHelper.showError(context, AppLocalizations.of(context)?.invalidQrCode ?? 'Invalid QR code format');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(syncSetupControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(_titleFor(setup.step, setup.selectedMode)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
          tooltip: 'Back',
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildStep(setup),
      ),
    );
  }

  Widget _buildStep(SyncSetupState setup) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final ctrl = ref.read(syncSetupControllerProvider.notifier);
    return ListView(
      key: ValueKey(setup.step),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      children: switch (setup.step) {
        SyncSetupStep.mode => [
            SyncModeStep(
              onSelectMode: ctrl.selectMode,
              onStayOffline: () => Navigator.pop(context),
            ),
          ],
        SyncSetupStep.credentials => [
            ListenableBuilder(
              listenable: Listenable.merge([_urlController, _keyController]),
              builder: (context, _) {
                final canContinue = _urlController.text.trim().isNotEmpty &&
                    _keyController.text.trim().isNotEmpty;
                return SyncCredentialsStep(
                  selectedMode: setup.selectedMode,
                  urlController: _urlController,
                  keyController: _keyController,
                  showKey: setup.showKey,
                  onToggleKeyVisibility: ctrl.toggleKeyVisibility,
                  onScanQr: _scanQr,
                  onContinue: canContinue
                      ? () => ctrl.goToStep(SyncSetupStep.auth)
                      : null,
                  // Rebuild handled by ListenableBuilder above; no-op.
                  onChanged: () {},
                );
              },
            ),
          ],
        SyncSetupStep.auth => [
            AuthFormWidget(
              onSubmit: _onAuthSubmit,
              isLoading: setup.isLoading,
              error: setup.error,
            ),
          ],
        SyncSetupStep.done => const [SyncDoneStep()],
      },
    );
  }
}
