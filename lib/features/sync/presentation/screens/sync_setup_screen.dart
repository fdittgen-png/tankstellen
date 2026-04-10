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
import '../widgets/sync_mode_card.dart';

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

  String _titleFor(SyncSetupStep step, SyncMode mode) => switch (step) {
        SyncSetupStep.mode => 'Connect TankSync',
        SyncSetupStep.credentials =>
          mode == SyncMode.private ? 'Your database' : 'Join a group',
        SyncSetupStep.auth => 'Your account',
        SyncSetupStep.done => 'Connected!',
      };

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
        SyncSetupStep.mode => _buildModeStep(),
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
        SyncSetupStep.done => _buildDoneStep(),
      },
    );
  }

  List<Widget> _buildModeStep() {
    final theme = Theme.of(context);
    final ctrl = ref.read(syncSetupControllerProvider.notifier);
    return [
      Semantics(
        header: true,
        child: Text('How would you like to sync?', style: theme.textTheme.titleMedium),
      ),
      const SizedBox(height: 4),
      Text(
        'Your app works fully offline. Cloud sync is optional.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),

      Semantics(
        label: 'Tankstellen Community, shared. Share favorites and ratings with all users.',
        button: true,
        child: SyncModeCard(
          icon: Icons.public,
          title: 'Tankstellen Community',
          subtitle: 'Share favorites & ratings with all users',
          privacyLabel: 'Shared',
          privacyColor: Colors.green,
          onTap: () => ctrl.selectMode(SyncMode.community),
        ),
      ),
      const SizedBox(height: 10),

      Semantics(
        label: 'Private Database, private. Your own Supabase, full data control.',
        button: true,
        child: SyncModeCard(
          icon: Icons.lock_outline,
          title: 'Private Database',
          subtitle: 'Your own Supabase — full data control',
          privacyLabel: 'Private',
          privacyColor: Colors.blue,
          onTap: () => ctrl.selectMode(SyncMode.private),
        ),
      ),
      const SizedBox(height: 10),

      Semantics(
        label: 'Join a Group, group access. Family or friends shared database.',
        button: true,
        child: SyncModeCard(
          icon: Icons.group_outlined,
          title: 'Join a Group',
          subtitle: 'Family or friends shared database',
          privacyLabel: 'Group',
          privacyColor: Colors.orange,
          onTap: () => ctrl.selectMode(SyncMode.joinExisting),
        ),
      ),

      const SizedBox(height: 24),
      Center(
        child: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.signal_wifi_off, size: 16),
          label: const Text('Stay offline'),
        ),
      ),
    ];
  }

  List<Widget> _buildDoneStep() {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 40),
      Semantics(
        label: 'Successfully connected. Your data will now sync automatically.',
        liveRegion: true,
        child: Column(
          children: [
            const ExcludeSemantics(
              child: Icon(Icons.check_circle, size: 64, color: Colors.green),
            ),
            const SizedBox(height: 16),
            Text('Successfully connected!', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Your data will now sync automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ];
  }
}
