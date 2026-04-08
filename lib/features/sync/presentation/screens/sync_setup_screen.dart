import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
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
class SyncSetupScreen extends ConsumerStatefulWidget {
  const SyncSetupScreen({super.key});

  @override
  ConsumerState<SyncSetupScreen> createState() => _SyncSetupScreenState();
}

enum _Step { mode, credentials, auth, done }

class _SyncSetupScreenState extends ConsumerState<SyncSetupScreen> {
  _Step _step = _Step.mode;
  SyncMode _selectedMode = SyncMode.none;
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _showKey = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  String get _title => switch (_step) {
    _Step.mode => 'Connect TankSync',
    _Step.credentials => _selectedMode == SyncMode.private ? 'Your database' : 'Join a group',
    _Step.auth => 'Your account',
    _Step.done => 'Connected!',
  };

  void _onBack() {
    switch (_step) {
      case _Step.mode:
        Navigator.pop(context);
      case _Step.credentials:
        setState(() => _step = _Step.mode);
      case _Step.auth:
        setState(() => _step = _selectedMode == SyncMode.community ? _Step.mode : _Step.credentials);
      case _Step.done:
        Navigator.pop(context);
    }
  }

  void _selectMode(SyncMode mode) {
    _selectedMode = mode;
    setState(() {
      if (mode == SyncMode.community) {
        _step = _Step.auth;
      } else {
        _step = _Step.credentials;
      }
    });
  }

  Future<void> _onAuthSubmit({
    required bool isEmail,
    String? email,
    String? password,
    required bool isSignUp,
  }) async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final syncNotifier = ref.read(syncStateProvider.notifier);

      if (_selectedMode == SyncMode.community) {
        await syncNotifier.connectCommunity();
      } else {
        final url = _urlController.text.trim();
        final key = _keyController.text.trim();
        await syncNotifier.connect(url, key, mode: _selectedMode);
      }

      if (isEmail && email != null && password != null) {
        await syncNotifier.signInWithEmail(email, password, isSignUp: isSignUp);
      }

      if (mounted) setState(() => _step = _Step.done);

      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        setState(() {});
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
    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(_title),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
          tooltip: 'Back',
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildStep(),
      ),
    );
  }

  Widget _buildStep() {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return ListView(
      key: ValueKey(_step),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPad),
      children: switch (_step) {
        _Step.mode => _buildModeStep(),
        _Step.credentials => [
          SyncCredentialsStep(
            selectedMode: _selectedMode,
            urlController: _urlController,
            keyController: _keyController,
            showKey: _showKey,
            onToggleKeyVisibility: () => setState(() => _showKey = !_showKey),
            onScanQr: _scanQr,
            onContinue: (_urlController.text.trim().isNotEmpty && _keyController.text.trim().isNotEmpty)
                ? () => setState(() => _step = _Step.auth)
                : null,
            onChanged: () => setState(() {}),
          ),
        ],
        _Step.auth => [
          AuthFormWidget(
            onSubmit: _onAuthSubmit,
            isLoading: _isLoading,
            error: _error,
          ),
        ],
        _Step.done => _buildDoneStep(),
      },
    );
  }

  List<Widget> _buildModeStep() {
    final theme = Theme.of(context);
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
          onTap: () => _selectMode(SyncMode.community),
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
          onTap: () => _selectMode(SyncMode.private),
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
          onTap: () => _selectMode(SyncMode.joinExisting),
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
