import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/sync/supabase_client.dart';
import '../../../../core/sync/sync_config.dart';
import '../../../../core/sync/sync_provider.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../alerts/providers/alert_provider.dart';
import '../../../favorites/providers/favorites_provider.dart';

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

    // Force sync local favorites to server
    try {
      final favoriteIds = ref.read(favoritesProvider);
      debugPrint('DataTransparency: forcing sync of ${favoriteIds.length} local favorites');
      debugPrint('DataTransparency: auth user = ${TankSyncClient.client?.auth.currentUser?.id}');
      debugPrint('DataTransparency: client initialized = ${TankSyncClient.isConnected}');

      if (!TankSyncClient.isConnected) {
        debugPrint('DataTransparency: not connected, attempting re-auth...');
        await TankSyncClient.signInAnonymously(); // This now also creates public.users row
        debugPrint('DataTransparency: re-auth result = ${TankSyncClient.client?.auth.currentUser?.id}');
      } else {
        // Ensure public.users row exists even for existing sessions
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

      // Also sync alerts
      final alerts = ref.read(alertProvider);
      debugPrint('DataTransparency: syncing ${alerts.length} local alerts');
      await SyncService.syncAlerts(alerts);
    } catch (e) {
      debugPrint('DataTransparency: force sync failed: $e');
    }

    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync completed — data refreshed')),
      );
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
        setState(() {
          _error = data['error'] as String;
          _loading = false;
        });
      } else {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int _countItems(Map<String, dynamic> data) {
    int count = 0;
    for (final value in data.values) {
      if (value is List) count += value.length;
    }
    return count;
  }

  String _estimateSize(Map<String, dynamic> data) {
    final json = const JsonEncoder().convert(data);
    final bytes = utf8.encode(json).length;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
            child: SelectableText(
              json,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportJson() async {
    if (_data == null) return;
    final json = _prettyJson(_data!);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('JSON copied to clipboard')),
    );
  }

  Future<void> _deleteAllData() async {
    final syncConfig = ref.read(syncStateProvider);
    final userId = syncConfig.userId;
    if (userId == null) return;

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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All server data deleted')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
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
      appBar: AppBar(
        title: const Text('My server data'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Account info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _InfoRow(
                              label: 'Anonymous UUID',
                              value: syncConfig.userId ?? 'Unknown',
                            ),
                            _InfoRow(
                              label: 'Server',
                              value: syncConfig.supabaseUrl ?? 'Unknown',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Data summary
                    if (_data != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Synced data',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _InfoRow(
                                label: 'Favorites',
                                value:
                                    '${(_data!['favorites'] as List?)?.length ?? 0}',
                              ),
                              _InfoRow(
                                label: 'Alerts',
                                value:
                                    '${(_data!['alerts'] as List?)?.length ?? 0}',
                              ),
                              _InfoRow(
                                label: 'Push tokens',
                                value:
                                    '${(_data!['push_tokens'] as List?)?.length ?? 0}',
                              ),
                              _InfoRow(
                                label: 'Price reports',
                                value:
                                    '${(_data!['reports'] as List?)?.length ?? 0}',
                              ),
                              const Divider(height: 24),
                              _InfoRow(
                                label: 'Total items',
                                value: '${_countItems(_data!)}',
                              ),
                              _InfoRow(
                                label: 'Estimated size',
                                value: _estimateSize(_data!),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sync Now button
                      FilledButton.icon(
                        onPressed: _loading ? null : _forceSyncAndReload,
                        icon: const Icon(Icons.sync),
                        label: const Text('Sync now'),
                      ),
                      const SizedBox(height: 8),

                      // Actions
                      OutlinedButton.icon(
                        onPressed: _showRawJson,
                        icon: const Icon(Icons.code),
                        label: const Text('View raw data as JSON'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _exportJson,
                        icon: const Icon(Icons.copy),
                        label: const Text('Export as JSON (clipboard)'),
                      ),
                      const SizedBox(height: 24),

                      // Destructive actions — disabled for community mode
                      if (syncConfig.mode == SyncMode.community) ...[
                        const Card(
                          color: Color(0xFFFFF3E0),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Color(0xFFE65100)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Data deletion is not available in community '
                                    'mode. Disconnect first, or use a private database.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ] else ...[
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: _deleteAllData,
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete all server data'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _disconnect,
                        icon: const Icon(Icons.link_off),
                        label: const Text('Disconnect TankSync'),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
