import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';
import '../../../../core/widgets/snackbar_helper.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/data_transparency_cards.dart';

/// Shows all data stored on the server for the current user.
class DataTransparencyScreen extends ConsumerStatefulWidget {
  const DataTransparencyScreen({super.key});

  @override
  ConsumerState<DataTransparencyScreen> createState() =>
      _DataTransparencyScreenState();
}

class _DataTransparencyScreenState
    extends ConsumerState<DataTransparencyScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _forceSyncAndReload() async {
    setState(() => _loading = true);

    try {
      final favoriteIds = ref.read(favoritesProvider);
      debugPrint('DataTransparency: forcing sync of ${favoriteIds.length} local favorites');
      debugPrint('DataTransparency: auth user = ${TankSyncClient.client?.auth.currentUser?.id}');
      debugPrint('DataTransparency: client initialized = ${TankSyncClient.isConnected}');

      if (!TankSyncClient.isConnected) {
        debugPrint('DataTransparency: not connected, attempting re-auth...');
        await TankSyncClient.signInAnonymously();
        debugPrint('DataTransparency: re-auth result = ${TankSyncClient.client?.auth.currentUser?.id}');
      } else {
        final uid = TankSyncClient.client?.auth.currentUser?.id;
        if (uid != null) {
          try {
            await TankSyncClient.client!.from('users').upsert({'id': uid}, onConflict: 'id');
          } catch (e) {
            debugPrint('DataTransparency: users upsert failed: $e');
          }
        }
      }

      await SyncService.syncFavorites(favoriteIds);

      final alerts = ref.read(alertProvider);
      debugPrint('DataTransparency: syncing ${alerts.length} local alerts');
      await SyncService.syncAlerts(alerts);
    } catch (e) {
      debugPrint('DataTransparency: force sync failed: $e');
    }

    await _loadData();
    if (mounted) {
      SnackBarHelper.showSuccess(context, AppLocalizations.of(context)?.syncCompleted ?? 'Sync completed — data refreshed');
    }
  }

  Future<void> _loadData() async {
    final syncConfig = ref.read(syncStateProvider);
    final storedUserId = syncConfig.userId;
    final sessionUserId = TankSyncClient.client?.auth.currentUser?.id;

    debugPrint('DataTransparency._loadData: storedUserId=$storedUserId, sessionUserId=$sessionUserId, isConnected=${TankSyncClient.isConnected}');

    if (storedUserId == null && sessionUserId == null) {
      setState(() {
        _error = 'No user ID found. Try disconnecting and reconnecting TankSync.';
        _loading = false;
      });
      return;
    }

    try {
      final data = await SyncService.fetchAllUserData();
      if (data.containsKey('error')) {
        setState(() { _error = data['error'] as String; _loading = false; });
      } else {
        setState(() { _data = data; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _prettyJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> _showRawJson() async {
    if (_data == null) return;
    final json = _prettyJson(_data!);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raw data (JSON)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(json, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    if (_data == null) return;
    await Clipboard.setData(ClipboardData(text: _prettyJson(_data!)));
    if (!mounted) return;
    SnackBarHelper.show(context, AppLocalizations.of(context)?.jsonCopied ?? 'JSON copied to clipboard');
  }

  Future<void> _deleteAllData() async {
    final syncConfig = ref.read(syncStateProvider);
    if (syncConfig.userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete all server data?'),
        content: const Text(
          'This will permanently remove all your favorites, alerts, push '
          'tokens, and price reports from the server. Your local data will '
          'not be affected.\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await SyncService.deleteAllUserData();
      await _loadData();
      if (!mounted) return;
      SnackBarHelper.showSuccess(context, AppLocalizations.of(context)?.allDataDeleted ?? 'All server data deleted');
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect TankSync?'),
        content: const Text(
          'You will be signed out from cloud sync. Your local data remains '
          'intact. You can reconnect at any time.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Disconnect')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await ref.read(syncStateProvider.notifier).disconnect();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final syncConfig = ref.watch(syncStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('My server data')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    AccountInfoCard(syncConfig: syncConfig),
                    const SizedBox(height: 12),
                    if (_data != null) ...[
                      SyncedDataCard(data: _data!),
                      const SizedBox(height: 16),
                      DataActionButtons(
                        loading: _loading,
                        mode: syncConfig.mode,
                        onSync: _forceSyncAndReload,
                        onViewRawJson: _showRawJson,
                        onExportJson: _exportJson,
                        onDeleteAll: _deleteAllData,
                        onDisconnect: _disconnect,
                      ),
                    ],
                  ],
                ),
    );
  }
}
