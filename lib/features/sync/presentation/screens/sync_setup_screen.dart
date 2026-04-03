import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
import '../widgets/auth_form_widget.dart';
import '../widgets/sync_mode_card.dart';

/// Clean 3-step sync setup: Mode → Credentials (if needed) → Auth → Done.
///
/// ## Architecture
/// - UI only — no business logic. Delegates all sync operations to [SyncState].
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
        _step = _Step.auth; // No credentials needed
      } else {
        _step = _Step.credentials; // Need URL + key
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

      // Step 1: Connect to database
      if (_selectedMode == SyncMode.community) {
        await syncNotifier.connectCommunity();
      } else {
        final url = _urlController.text.trim();
        final key = _keyController.text.trim();
        await syncNotifier.connect(url, key, mode: _selectedMode);
      }

      // Step 2: Email auth (if chosen)
      if (isEmail && email != null && password != null) {
        await syncNotifier.signInWithEmail(email, password, isSignUp: isSignUp);
      }

      if (mounted) setState(() => _step = _Step.done);

      // Auto-close after brief success display
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
      MaterialPageRoute(builder: (_) => const _QrScannerPage()),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR code format')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _onBack),
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
        _Step.credentials => _buildCredentialsStep(),
        _Step.auth => _buildAuthStep(),
        _Step.done => _buildDoneStep(),
      },
    );
  }

  // ── Step 1: Choose sync mode ──────────────────────────────────────────

  List<Widget> _buildModeStep() {
    final theme = Theme.of(context);
    return [
      Text('How would you like to sync?', style: theme.textTheme.titleMedium),
      const SizedBox(height: 4),
      Text(
        'Your app works fully offline. Cloud sync is optional.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 20),

      SyncModeCard(
        icon: Icons.public,
        title: 'Tankstellen Community',
        subtitle: 'Share favorites & ratings with all users',
        privacyLabel: 'Shared',
        privacyColor: Colors.green,
        onTap: () => _selectMode(SyncMode.community),
      ),
      const SizedBox(height: 10),

      SyncModeCard(
        icon: Icons.lock_outline,
        title: 'Private Database',
        subtitle: 'Your own Supabase — full data control',
        privacyLabel: 'Private',
        privacyColor: Colors.blue,
        onTap: () => _selectMode(SyncMode.private),
      ),
      const SizedBox(height: 10),

      SyncModeCard(
        icon: Icons.group_outlined,
        title: 'Join a Group',
        subtitle: 'Family or friends shared database',
        privacyLabel: 'Group',
        privacyColor: Colors.orange,
        onTap: () => _selectMode(SyncMode.joinExisting),
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

  // ── Step 2: Credentials (private / join existing) ─────────────────────

  List<Widget> _buildCredentialsStep() {
    final theme = Theme.of(context);
    final hasInput = _urlController.text.trim().isNotEmpty && _keyController.text.trim().isNotEmpty;
    final keyLen = _keyController.text.length;

    return [
      if (_selectedMode == SyncMode.joinExisting) ...[
        FilledButton.icon(
          onPressed: _scanQr,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 6),
        Text(
          'Ask the database owner to show their QR code',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or enter manually')),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 16),
      ],

      if (_selectedMode == SyncMode.private) ...[
        Text(
          'Enter your Supabase project credentials. You can find them in your dashboard under Settings > API.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
      ],

      TextField(
        controller: _urlController,
        decoration: const InputDecoration(
          labelText: 'Database URL',
          hintText: 'https://your-project.supabase.co',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.link, size: 18),
          isDense: true,
        ),
        maxLines: 1,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _keyController,
        decoration: InputDecoration(
          labelText: 'Access Key',
          hintText: 'eyJhbGciOiJIUzI1NiIs...',
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.key, size: 18),
          isDense: true,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (keyLen > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text('$keyLen', style: TextStyle(fontSize: 10,
                    color: keyLen >= 200 ? Colors.green : Colors.orange)),
                ),
              IconButton(
                icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility, size: 18),
                onPressed: () => setState(() => _showKey = !_showKey),
              ),
            ],
          ),
        ),
        obscureText: !_showKey,
        maxLines: _showKey ? 3 : 1,
        style: TextStyle(fontSize: _showKey ? 10 : 13),
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: hasInput ? () => setState(() => _step = _Step.auth) : null,
        child: const Text('Continue'),
      ),
    ];
  }

  // ── Step 3: Authentication ────────────────────────────────────────────

  List<Widget> _buildAuthStep() {
    return [
      AuthFormWidget(
        onSubmit: _onAuthSubmit,
        isLoading: _isLoading,
        error: _error,
      ),
    ];
  }

  // ── Step 4: Done ──────────────────────────────────────────────────────

  List<Widget> _buildDoneStep() {
    final theme = Theme.of(context);
    return [
      const SizedBox(height: 40),
      const Icon(Icons.check_circle, size: 64, color: Colors.green),
      const SizedBox(height: 16),
      Text('Successfully connected!', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
      const SizedBox(height: 8),
      Text(
        'Your data will now sync automatically.',
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        textAlign: TextAlign.center,
      ),
    ];
  }
}

// ── QR Scanner (extracted) ──────────────────────────────────────────────

class _QrScannerPage extends StatefulWidget {
  const _QrScannerPage();
  @override
  State<_QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<_QrScannerPage> {
  bool _scanned = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_scanned) return;
          final barcode = capture.barcodes.firstOrNull;
          if (barcode?.rawValue != null) {
            _scanned = true;
            Navigator.pop(context, barcode!.rawValue);
          }
        },
      ),
    );
  }
}
