import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/sync/schema_verifier.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../widgets/anon_key_field.dart';
import '../widgets/qr_scanner_screen.dart';
import '../widgets/wizard_auth_step.dart';
import '../widgets/wizard_choose_mode.dart';
import '../widgets/wizard_create_new.dart';
import '../widgets/wizard_join_existing.dart';
import '../widgets/wizard_schema_step.dart';

/// Multi-step wizard for setting up TankSync database connection.
///
/// Supports two flows:
/// 1. **Create new database** — guided Supabase project creation with screenshots
/// 2. **Join existing database** — QR code scan or manual URL+key entry
///
/// After connecting, verifies the database schema and guides the user
/// to deploy missing tables if needed.
class SyncWizardScreen extends ConsumerStatefulWidget {
  const SyncWizardScreen({super.key});

  @override
  ConsumerState<SyncWizardScreen> createState() => _SyncWizardScreenState();
}

enum _WizardMode { choose, createNew, joinExisting, auth, schema }

class _SyncWizardScreenState extends ConsumerState<SyncWizardScreen> {
  _WizardMode _mode = _WizardMode.choose;
  int _createStep = 0;

  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _testing = false;
  bool _connecting = false;
  bool _isSignUp = true;
  bool _useEmail = false;
  String? _testResult;
  bool _testSuccess = false;
  Map<String, bool>? _schemaStatus;
  String? _migrationSql;
  bool _showKey = false;

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Widget _buildKeyField() {
    return AnonKeyField(
      controller: _keyController,
      showKey: _showKey,
      onToggleVisibility: () => setState(() => _showKey = !_showKey),
      onChanged: () => setState(() {}),
    );
  }

  String _sanitizeUrl(String raw) {
    var url = raw.replaceAll(RegExp(r'\s+'), '').replaceAll(RegExp(r'/+$'), '');
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    final host = Uri.tryParse(url)?.host ?? '';
    final idx = host.indexOf('.supabase.co');
    if (idx > 0) {
      return 'https://${host.substring(0, idx + 12)}';
    }
    return url;
  }

  String _sanitizeKey(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < AnonKeyField.minExpectedKeyLength) {
      debugPrint('Warning: Anon key is ${cleaned.length} chars, expected ${AnonKeyField.minExpectedKeyLength}');
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect TankSync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_mode == _WizardMode.choose) {
              Navigator.pop(context);
            } else if (_mode == _WizardMode.schema) {
              setState(() => _mode = _WizardMode.auth);
            } else {
              setState(() => _mode = _WizardMode.choose);
            }
          },
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          if (_mode == _WizardMode.choose)
            WizardChooseMode(
              onCreateNew: () => setState(() => _mode = _WizardMode.createNew),
              onJoinExisting: () => setState(() => _mode = _WizardMode.joinExisting),
            ),
          if (_mode == _WizardMode.createNew)
            WizardCreateNew(
              currentStep: _createStep,
              urlController: _urlController,
              keyController: _keyController,
              keyField: _buildKeyField(),
              onBack: () => setState(() => _createStep--),
              onNext: () => setState(() => _createStep++),
              onContinue: (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
                  ? () => setState(() => _mode = _WizardMode.auth)
                  : null,
            ),
          if (_mode == _WizardMode.joinExisting)
            WizardJoinExisting(
              urlController: _urlController,
              keyController: _keyController,
              keyField: _buildKeyField(),
              onScanQr: _openQrScanner,
              onContinue: (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
                  ? () => setState(() => _mode = _WizardMode.auth)
                  : null,
            ),
          if (_mode == _WizardMode.auth)
            WizardAuthStep(
              useEmail: _useEmail,
              isSignUp: _isSignUp,
              testing: _testing,
              connecting: _connecting,
              testResult: _testResult,
              testSuccess: _testSuccess,
              emailController: _emailController,
              passwordController: _passwordController,
              onUseEmailChanged: (value) => setState(() => _useEmail = value),
              onToggleSignUp: () => setState(() => _isSignUp = !_isSignUp),
              onTestConnection: _testConnection,
              onConnect: _connect,
            ),
          if (_mode == _WizardMode.schema)
            WizardSchemaStep(
              schemaStatus: _schemaStatus,
              migrationSql: _migrationSql,
              onRecheck: () async {
                final status = await SchemaVerifier.checkSchema();
                if (mounted) setState(() => _schemaStatus = status);
              },
              onDone: () {
                SnackBarHelper.showSuccess(context, AppLocalizations.of(context)?.tankSyncConnected ?? 'TankSync connected!');
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (result != null && mounted) {
      try {
        final json = jsonDecode(result) as Map<String, dynamic>;
        _urlController.text = json['url']?.toString() ?? '';
        _keyController.text = json['key']?.toString() ?? '';
        setState(() => _mode = _WizardMode.auth);
      } catch (e) {
        debugPrint('QR code parse failed: $e');
        SnackBarHelper.showError(context, AppLocalizations.of(context)?.invalidQrCodeTankSync ?? 'Invalid QR code — expected TankSync format');
      }
    }
  }

  Future<void> _testConnection() async {
    setState(() { _testing = true; _testResult = null; });
    try {
      final url = _sanitizeUrl(_urlController.text);
      final key = _sanitizeKey(_keyController.text);
      await TankSyncClient.init(url: url, anonKey: key);
      setState(() { _testResult = 'Connection successful!'; _testSuccess = true; _testing = false; });
    } catch (e) {
      setState(() { _testResult = 'Connection failed:\n$e'; _testSuccess = false; _testing = false; });
    }
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final url = _sanitizeUrl(_urlController.text);
      final key = _sanitizeKey(_keyController.text);

      if (_useEmail && _emailController.text.isNotEmpty && (_isSignUp ? _passwordController.text.length >= 6 : _passwordController.text.isNotEmpty)) {
        await TankSyncClient.init(url: url, anonKey: key);
        String? userId;
        if (_isSignUp) {
          userId = await TankSyncClient.signUpWithEmail(_emailController.text.trim(), _passwordController.text);
        } else {
          userId = await TankSyncClient.signInWithEmail(_emailController.text.trim(), _passwordController.text);
        }
        final settings = ref.read(settingsStorageProvider);
        await settings.putSetting('sync_enabled', true);
        await settings.putSetting('supabase_url', url);
        await settings.putSetting('supabase_anon_key', key);
        if (userId != null) await settings.putSetting('sync_user_id', userId);
        ref.invalidate(syncStateProvider);
      } else {
        await ref.read(syncStateProvider.notifier).connect(url, key);
      }

      if (!mounted) return;
      final schema = await SchemaVerifier.checkSchema();
      if (schema != null && mounted) {
        final allReady = SchemaVerifier.requiredTables.every((t) => schema[t] == true);
        if (allReady) {
          SnackBarHelper.showSuccess(context, AppLocalizations.of(context)?.tankSyncConnected ?? 'TankSync connected!');
          Navigator.pop(context);
        } else {
          setState(() {
            _schemaStatus = schema;
            _migrationSql = SchemaVerifier.getMigrationSql(schema);
            _mode = _WizardMode.schema;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() { _testResult = 'Connection failed: $e'; _testSuccess = false; });
      }
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }
}
