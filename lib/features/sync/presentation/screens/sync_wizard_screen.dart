import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/widgets/page_scaffold.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/sync/schema_verifier.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../providers/sync_wizard_provider.dart';
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
///
/// Wizard state (mode, toggles, progress) lives in
/// [syncWizardControllerProvider]; only text controllers remain local.
class SyncWizardScreen extends ConsumerStatefulWidget {
  const SyncWizardScreen({super.key});

  @override
  ConsumerState<SyncWizardScreen> createState() => _SyncWizardScreenState();
}

class _SyncWizardScreenState extends ConsumerState<SyncWizardScreen> {
  final _urlController = TextEditingController();
  final _keyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(syncWizardControllerProvider.notifier).reset();
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  SyncWizardController get _notifier =>
      ref.read(syncWizardControllerProvider.notifier);

  Widget _buildKeyField() {
    final showKey =
        ref.watch(syncWizardControllerProvider.select((s) => s.showKey));
    return AnonKeyField(
      controller: _keyController,
      showKey: showKey,
      onToggleVisibility: _notifier.toggleKeyVisibility,
      onChanged: _notifier.touch,
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
    final wizard = ref.watch(syncWizardControllerProvider);
    return PageScaffold(
      title: 'Connect TankSync',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: AppLocalizations.of(context)?.tooltipBack ?? 'Back',
        onPressed: () {
          if (wizard.mode == SyncWizardMode.choose) {
            Navigator.pop(context);
          } else if (wizard.mode == SyncWizardMode.schema) {
            _notifier.setMode(SyncWizardMode.auth);
          } else {
            _notifier.setMode(SyncWizardMode.choose);
          }
        },
      ),
      bodyPadding: EdgeInsets.zero,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        children: [
          if (wizard.mode == SyncWizardMode.choose)
            WizardChooseMode(
              onCreateNew: () => _notifier.setMode(SyncWizardMode.createNew),
              onJoinExisting: () =>
                  _notifier.setMode(SyncWizardMode.joinExisting),
            ),
          if (wizard.mode == SyncWizardMode.createNew)
            WizardCreateNew(
              currentStep: wizard.createStep,
              urlController: _urlController,
              keyController: _keyController,
              keyField: _buildKeyField(),
              onBack: _notifier.decrementStep,
              onNext: _notifier.incrementStep,
              onContinue: (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
                  ? () => _notifier.setMode(SyncWizardMode.auth)
                  : null,
            ),
          if (wizard.mode == SyncWizardMode.joinExisting)
            WizardJoinExisting(
              urlController: _urlController,
              keyController: _keyController,
              keyField: _buildKeyField(),
              onScanQr: _openQrScanner,
              onContinue: (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
                  ? () => _notifier.setMode(SyncWizardMode.auth)
                  : null,
            ),
          if (wizard.mode == SyncWizardMode.auth)
            WizardAuthStep(
              useEmail: wizard.useEmail,
              isSignUp: wizard.isSignUp,
              testing: wizard.testing,
              connecting: wizard.connecting,
              testResult: wizard.testResult,
              testSuccess: wizard.testSuccess,
              emailController: _emailController,
              passwordController: _passwordController,
              onUseEmailChanged: _notifier.setUseEmail,
              onToggleSignUp: _notifier.toggleSignUp,
              onTestConnection: _testConnection,
              onConnect: _connect,
              onPasswordChanged: _notifier.touch,
            ),
          if (wizard.mode == SyncWizardMode.schema)
            WizardSchemaStep(
              schemaStatus: wizard.schemaStatus,
              migrationSql: wizard.migrationSql,
              onRecheck: () async {
                final status = await SchemaVerifier.checkSchema();
                if (mounted) _notifier.updateSchemaStatus(status);
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
        _notifier.setMode(SyncWizardMode.auth);
      } catch (e) {
        debugPrint('QR code parse failed: $e');
        SnackBarHelper.showError(context, AppLocalizations.of(context)?.invalidQrCodeTankSync ?? 'Invalid QR code — expected TankSync format');
      }
    }
  }

  Future<void> _testConnection() async {
    _notifier.startTesting();
    try {
      final url = _sanitizeUrl(_urlController.text);
      final key = _sanitizeKey(_keyController.text);
      await TankSyncClient.init(url: url, anonKey: key);
      _notifier.testSucceeded('Connection successful!');
    } catch (e) {
      _notifier.testFailed('Connection failed:\n$e');
    }
  }

  Future<void> _connect() async {
    _notifier.setConnecting(true);
    try {
      final wizard = ref.read(syncWizardControllerProvider);
      final url = _sanitizeUrl(_urlController.text);
      final key = _sanitizeKey(_keyController.text);

      if (wizard.useEmail && _emailController.text.isNotEmpty && (wizard.isSignUp ? PasswordValidator.isValid(_passwordController.text) : _passwordController.text.isNotEmpty)) {
        await TankSyncClient.init(url: url, anonKey: key);
        String? userId;
        if (wizard.isSignUp) {
          userId = await TankSyncClient.signUpWithEmail(_emailController.text.trim(), _passwordController.text);
        } else {
          userId = await TankSyncClient.signInWithEmail(_emailController.text.trim(), _passwordController.text);
        }
        final settings = ref.read(settingsStorageProvider);
        final apiKeys = ref.read(apiKeyStorageProvider);
        await settings.putSetting('sync_enabled', true);
        await settings.putSetting('supabase_url', url);
        await apiKeys.setSupabaseAnonKey(key);
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
          _notifier.showSchemaStep(
            schema: schema,
            migrationSql: SchemaVerifier.getMigrationSql(schema),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _notifier.connectFailed('Connection failed: $e');
      }
    } finally {
      if (mounted) _notifier.setConnecting(false);
    }
  }
}
