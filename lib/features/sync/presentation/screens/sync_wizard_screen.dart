import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/storage/storage_providers.dart';
import '../../../../core/sync/schema_verifier.dart';
import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';

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
  int _createStep = 0; // 0-3 for the "create new" guided flow

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

  /// Minimum expected length of a Supabase anon key (JWT token).
  /// Standard structure: Header(36) + "." + Payload(~127) + "." + Signature(43) = ~208
  /// Payload length varies slightly with project ref length (always 20 chars currently).
  static const _minExpectedKeyLength = 200;
  /// Safe upper bound for key length validation (allows for future changes).
  static const _maxKeyLength = 512;

  /// Builds the anon key text field with:
  /// - Visibility toggle (eye icon) to verify the full key was pasted
  /// - Character count with color (green=correct, orange=truncated)
  /// - Helper text explaining expected length
  Widget _buildKeyField() {
    final keyLen = _keyController.text.length;
    final isComplete = keyLen >= _minExpectedKeyLength;
    final isTooLong = keyLen > _maxKeyLength;
    // Check if it looks like a JWT (3 dot-separated parts)
    final isJwtFormat = _keyController.text.split('.').length == 3;

    String? helperText;
    Color helperColor = Colors.orange;
    if (keyLen > 0) {
      if (isTooLong) {
        helperText = 'Key is too long ($keyLen chars) — check for extra text';
        helperColor = Colors.red;
      } else if (isComplete && isJwtFormat) {
        helperText = 'Key looks correct ($keyLen chars)';
        helperColor = Colors.green;
      } else if (!isJwtFormat && keyLen > 10) {
        helperText = 'Key should be a JWT (header.payload.signature)';
        helperColor = Colors.red;
      } else {
        helperText = 'Key may be truncated ($keyLen of ~208 expected chars)';
      }
    }

    return TextField(
      controller: _keyController,
      decoration: InputDecoration(
        labelText: 'Anon Key',
        hintText: 'eyJhbGciOiJIUzI1NiIs...',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.key),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (keyLen > 0)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '$keyLen',
                  style: TextStyle(fontSize: 11, color: isComplete ? Colors.green : Colors.orange),
                ),
              ),
            IconButton(
              icon: Icon(_showKey ? Icons.visibility_off : Icons.visibility, size: 20),
              onPressed: () => setState(() => _showKey = !_showKey),
              tooltip: _showKey ? 'Hide key' : 'Show key to verify',
            ),
          ],
        ),
        helperText: helperText,
        helperMaxLines: 2,
        helperStyle: TextStyle(color: helperColor, fontSize: 11),
        errorText: isTooLong ? 'Key exceeds maximum length' : null,
      ),
      obscureText: !_showKey,
      maxLines: _showKey ? 3 : 1, // Multi-line when visible so the full JWT is readable
      style: TextStyle(fontSize: _showKey ? 11 : 13),
      onChanged: (_) => setState(() {}),
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
    if (cleaned.length < _minExpectedKeyLength) {
      debugPrint('Warning: Anon key is ${cleaned.length} chars, expected $_minExpectedKeyLength');
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect TankSync'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_mode == _WizardMode.choose) {
              Navigator.pop(context);
            } else if (_mode == _WizardMode.createNew || _mode == _WizardMode.joinExisting) {
              setState(() => _mode = _WizardMode.choose);
            } else if (_mode == _WizardMode.auth) {
              setState(() => _mode = _WizardMode.choose);
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
          if (_mode == _WizardMode.choose) _buildChooseMode(theme),
          if (_mode == _WizardMode.createNew) _buildCreateNew(theme),
          if (_mode == _WizardMode.joinExisting) _buildJoinExisting(theme),
          if (_mode == _WizardMode.auth) _buildAuth(theme),
          if (_mode == _WizardMode.schema) _buildSchema(theme),
        ],
      ),
    );
  }

  // ─── Step 1: Choose mode ───────────────────────────────────────────────

  Widget _buildChooseMode(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info card
        Card(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('TankSync is optional',
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                ]),
                const SizedBox(height: 8),
                Text(
                  'Your app works fully without cloud sync. TankSync lets you sync '
                  'favorites, alerts, and ratings across devices using Supabase (free tier available).',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Text('How would you like to connect?', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // Option 1: Create new
        _WizardOptionCard(
          icon: Icons.add_circle_outline,
          title: 'Create my own database',
          subtitle: 'Free Supabase project — we\'ll guide you step by step',
          onTap: () => setState(() => _mode = _WizardMode.createNew),
        ),
        const SizedBox(height: 12),

        // Option 2: Join existing
        _WizardOptionCard(
          icon: Icons.qr_code_scanner,
          title: 'Join an existing database',
          subtitle: 'Scan QR code from the database owner or paste credentials',
          onTap: () => setState(() => _mode = _WizardMode.joinExisting),
        ),
      ],
    );
  }

  // ─── Create New: guided steps ──────────────────────────────────────────

  Widget _buildCreateNew(ThemeData theme) {
    final steps = [
      _GuideStep(
        title: 'Create a Supabase project',
        instructions: '1. Tap "Open Supabase" below\n'
            '2. Create a free account (if you don\'t have one)\n'
            '3. Click "New Project"\n'
            '4. Choose a name and region\n'
            '5. Wait ~2 minutes for it to start',
        actionLabel: 'Open Supabase',
        actionUrl: 'https://supabase.com/dashboard/new',
      ),
      _GuideStep(
        title: 'Enable Anonymous Sign-ins',
        instructions: '1. In your Supabase dashboard:\n'
            '   Authentication → Providers\n'
            '2. Find "Anonymous Sign-ins"\n'
            '3. Toggle it ON\n'
            '4. Click "Save"',
        actionLabel: 'Open Auth Settings',
        actionUrl: null, // Will be constructed with project URL
      ),
      _GuideStep(
        title: 'Copy your credentials',
        instructions: '1. Go to Settings → API in your dashboard\n'
            '2. Copy the "Project URL"\n'
            '3. Copy the "anon public" key\n'
            '4. Paste them below',
        actionLabel: 'Open API Settings',
        actionUrl: null,
      ),
    ];

    final step = steps[_createStep.clamp(0, steps.length - 1)];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_createStep + 1) / (steps.length + 1),
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16),

        Text('Step ${_createStep + 1} of ${steps.length + 1}',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)),
        const SizedBox(height: 8),
        Text(step.title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(step.instructions, style: theme.textTheme.bodyMedium),
          ),
        ),
        const SizedBox(height: 16),

        if (step.actionUrl != null)
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(step.actionUrl!), mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new),
            label: Text(step.actionLabel),
          ),

        if (_createStep == 2) ...[
          // Show URL + key input on step 3
          const SizedBox(height: 16),
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Supabase URL',
              hintText: 'https://your-project.supabase.co',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.link),
            ),
            maxLines: 1,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildKeyField(),
        ],

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_createStep > 0)
              TextButton(
                onPressed: () => setState(() => _createStep--),
                child: const Text('Back'),
              )
            else
              const SizedBox(),
            FilledButton(
              onPressed: _createStep < 2
                  ? () => setState(() => _createStep++)
                  : (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
                      ? () => setState(() => _mode = _WizardMode.auth)
                      : null,
              child: Text(_createStep < 2 ? 'Next' : 'Continue'),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Join Existing: QR scan or manual ──────────────────────────────────

  Widget _buildJoinExisting(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Join an existing database', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // QR Scanner
        FilledButton.icon(
          onPressed: _openQrScanner,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan QR Code'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 8),
        Text(
          'Ask the database owner to show you their QR code\n(Settings → TankSync → Share)',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or')),
          Expanded(child: Divider()),
        ]),
        const SizedBox(height: 24),

        // Manual entry
        Text('Enter manually', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Supabase URL',
            hintText: 'https://your-project.supabase.co',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
            helperText: 'Whitespace and line breaks removed automatically',
          ),
          maxLines: 1,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        _buildKeyField(),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: (_urlController.text.isNotEmpty && _keyController.text.isNotEmpty)
              ? () => setState(() => _mode = _WizardMode.auth)
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }

  // ─── Auth mode selection ───────────────────────────────────────────────

  Widget _buildAuth(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Choose your account type', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),

        // Anonymous
        _WizardOptionCard(
          icon: Icons.person_outline,
          title: 'Anonymous',
          subtitle: 'Instant, no email needed. Data tied to this device.',
          selected: !_useEmail,
          onTap: () => setState(() => _useEmail = false),
        ),
        const SizedBox(height: 12),

        // Email
        _WizardOptionCard(
          icon: Icons.email_outlined,
          title: 'Email Account',
          subtitle: 'Sign in from any device. Recover data if phone is lost.',
          selected: _useEmail,
          onTap: () => setState(() => _useEmail = true),
        ),

        if (_useEmail) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.lock),
              helperText: _isSignUp ? 'Minimum 6 characters' : null,
            ),
            obscureText: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isSignUp = !_isSignUp),
              child: Text(_isSignUp ? 'Already have an account? Sign in' : 'Create new account'),
            ),
          ),
        ],

        // Test + error display
        if (_testResult != null) ...[
          const SizedBox(height: 12),
          Card(
            color: _testSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_testSuccess ? Icons.check_circle : Icons.error,
                      color: _testSuccess ? Colors.green : Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_testResult!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: !_testing ? _testConnection : null,
                child: Text(_testing ? 'Testing...' : 'Test Connection'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: !_connecting ? _connect : null,
                child: Text(_connecting ? 'Connecting...' : 'Connect'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Schema verification ───────────────────────────────────────────────

  Widget _buildSchema(ThemeData theme) {
    if (_schemaStatus == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final allReady = SchemaVerifier.requiredTables.every((t) => _schemaStatus![t] == true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          allReady ? Icons.check_circle : Icons.warning_amber,
          size: 48,
          color: allReady ? Colors.green : Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          allReady ? 'Database ready!' : 'Database needs setup',
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Table status list
        for (final table in [...SchemaVerifier.requiredTables, ...SchemaVerifier.optionalTables])
          ListTile(
            dense: true,
            leading: Icon(
              _schemaStatus![table] == true ? Icons.check_circle : Icons.cancel,
              color: _schemaStatus![table] == true ? Colors.green : Colors.red,
              size: 18,
            ),
            title: Text(table, style: theme.textTheme.bodySmall),
            trailing: Text(
              _schemaStatus![table] == true ? 'OK' : 'Missing',
              style: TextStyle(
                fontSize: 11,
                color: _schemaStatus![table] == true ? Colors.green : Colors.red,
              ),
            ),
          ),

        if (!allReady) ...[
          const SizedBox(height: 16),
          Text(
            'Copy the SQL below and run it in your Supabase SQL Editor\n'
            '(Dashboard → SQL Editor → New Query → Paste → Run)',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _migrationSql ?? ''));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SQL copied to clipboard')),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy SQL to clipboard'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              // Re-verify after user runs SQL
              final status = await SchemaVerifier.checkSchema();
              if (mounted) setState(() => _schemaStatus = status);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Re-check schema'),
          ),
        ],

        if (allReady) ...[
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('TankSync connected!')),
              );
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ],
    );
  }

  // ─── Actions ───────────────────────────────────────────────────────────

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _QrScannerScreen()),
    );
    if (result != null && mounted) {
      try {
        final json = jsonDecode(result) as Map<String, dynamic>;
        _urlController.text = json['url']?.toString() ?? '';
        _keyController.text = json['key']?.toString() ?? '';
        setState(() => _mode = _WizardMode.auth);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid QR code — expected TankSync format')),
        );
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

      if (_useEmail && _emailController.text.isNotEmpty && _passwordController.text.length >= 6) {
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

      // Verify schema
      if (!mounted) return;
      final schema = await SchemaVerifier.checkSchema();
      if (schema != null && mounted) {
        final allReady = SchemaVerifier.requiredTables.every((t) => schema[t] == true);
        if (allReady) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TankSync connected!')));
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

// ─── Helper Widgets ──────────────────────────────────────────────────────

class _WizardOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _WizardOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: selected ? 2 : 0,
      color: selected ? theme.colorScheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: selected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideStep {
  final String title;
  final String instructions;
  final String actionLabel;
  final String? actionUrl;
  const _GuideStep({required this.title, required this.instructions, required this.actionLabel, this.actionUrl});
}

// ─── QR Scanner Screen ───────────────────────────────────────────────────

class _QrScannerScreen extends StatefulWidget {
  const _QrScannerScreen();

  @override
  State<_QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<_QrScannerScreen> {
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

// ─── QR Code Share Widget (for database owners) ──────────────────────────

/// Widget that generates a QR code containing the database credentials.
/// Used by database owners to share access with family/friends.
class QrShareWidget extends ConsumerWidget {
  const QrShareWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncStateProvider);
    if (!syncState.enabled || syncState.supabaseUrl == null || syncState.supabaseAnonKey == null) {
      return const SizedBox.shrink();
    }

    final qrData = jsonEncode({
      'url': syncState.supabaseUrl,
      'key': syncState.supabaseAnonKey,
    });

    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Share your database', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(
              'Others can scan this QR code to connect to your database',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: qrData));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Connection data copied')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy as text'),
            ),
          ],
        ),
      ),
    );
  }
}
